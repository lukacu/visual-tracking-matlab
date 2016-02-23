function [state, location, values] = tracker_lgt_initialize(image, region, varargin)

    parameters_constructor = str2func('lgt_parameters');
    additional_parameters = struct();
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'parameters'
                additional_parameters = varargin{i+1};
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    if isfield(additional_parameters, 'defaults')
        parameters_constructor = str2func(additional_parameters.defaults);
    end
    
    state.parameters = struct_merge(additional_parameters, parameters_constructor());
    
    print_structure(state.parameters);
    
    values = struct();

    % BASIC INITIALIZATION

    image = image_create(image);

    state.parts = parts_create(state.parameters.parts.type);
    state.modalities = modalities_create(state.parameters.modalities);
    
    if numel(region) > 5

        polygon_x = region(1:2:end);
        polygon_y = region(2:2:end);

        x1 = min(polygon_x);
        x2 = max(polygon_x);
        y1 = min(polygon_y);
        y2 = max(polygon_y);

        region = [x1, y1, x2 - x1, y2 - y1];

        state.use_polygon = true;

    else

        polygon_x = [region(1), region(1), region(1) + region(3), region(1) + region(3)];
        polygon_y = [region(2), region(2) + region(4), region(2) + region(4), region(2)];

        state.use_polygon = false;

    end;

    if isfield(state.parameters, 'use_polygon')
        state.use_polygon = logical(state.parameters.use_polygon);
    end
    
    state.scaling = 1 / mean(region(3:4) / 60); % TODO: this is a hard-coded hack
    state.mode = 0;

    image = image_resize(image, state.scaling);
    
    region = round(region .* state.scaling);
    polygon_y = polygon_y .* state.scaling;
    polygon_x = polygon_x .* state.scaling;
    
    [gray, image] = image_convert(image, 'gray');

    % INITIAL PARTS ...
    count = round( (region(4) * region(3)) / ( (4 * state.parameters.parts.merge) .^ 2));
    count = min(max(state.parameters.parts.min, count), state.parameters.parts.max);
    
    sx = floor(sqrt(count)) + 1;
    sy = ceil(sqrt(count)) + 1;
    
    if (region(4) < region(3))
        [sx, sy] = deal(sy, sx);
    end;
  
    % TODO: improve this!
    positions = zeros(sx * sy, 2);
    for i = 1:sx
        for j = 1:sy
            ox = region(1) + (region(3) / (sx))*(i-0.5);
            oy = region(2) + (region(4) / (sy))*(j-0.5);

            positions((i-1) * sy + j, :) = [ox oy];
        end
    end
    
    valid = inpolygon(positions(:,1), positions(:,2), polygon_x, polygon_y);
    positions = positions(valid, :);
    [state.parts, added] = parts_add(state.parts, image, positions, repmat(state.parameters.parts.part_size, size(positions, 1), 2));
    state.parts.importance(added) = 0.5;
    state.parts.group(added) = 1;

    state.parts = parts_push(state.parts);
    state.parts.capacity = parts_size(state.parts);
    
    state.image = image;
    
    % MOTION MODEL SETUP
    % syms T q;
    % F = [0, 0, 1, 0; 0, 0, 0, 1; 0, 0, 0, 0; 0, 0, 0, 0]; 
    % Fi = expm(F * T);
    % L = [0, 0; 0, 0; 1, 0; 0, 1];
    % Qs = int((Fi * L) * q * (Fi * L)', T, 0, T);
    % Q = double(subs(subs(Qs, T, 1), q, 1));
    % A = double(subs(subs(Fi, T, 1)));

    state.kalman_F = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1];
    state.kalman_H = [1 0 0 0; 0 1 0 0];

    state.kalman_R = eye(2);
    state.kalman_Q = [0.333, 0, 0.5, 0; 0, 0.333, 0, 0.5; 0.5, 0, 1, 0; 0, 0.5, 0, 1];

    state.kalman_state = [mean(state.parts.positions(state.parts.group == 1, :)) 0 0]';
    state.kalman_covariance = eye(4); 
    

    if state.use_polygon

        positions = state.parts.positions;
        positions = positions(state.parts.importance > 0, :);
        hull = convhull(positions(:, 1), positions(:, 2));
        positions = positions(hull, :);            

        p = poly2bb(positions(:, 1), positions(:, 2))';
        region = p(:)';

    end;
    
    state.previous = image;
    
    location = region ./ state.scaling;

end
