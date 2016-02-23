function [state, location, values] = tracker_ant_initialize(image, region, varargin)

    % PARAMETERS SETUP

    parameters_constructor = str2func('ant_parameters');
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
    
    % BASIC INITIALIZATION

    image = image_create(image);

    if numel(region) > 5

        polygon_x = region(1:2:end);
        polygon_y = region(2:2:end);

        x1 = min(polygon_x);
        x2 = max(polygon_x);
        y1 = min(polygon_y);
        y2 = max(polygon_y);

        bounding_box = [x1, y1, x2 - x1, y2 - y1];

        state.use_polygon = true;

    else

        bounding_box = region;
        
        polygon_x = [region(1), region(1), region(1) + region(3), region(1) + region(3)];
        polygon_y = [region(2), region(2) + region(4), region(2) + region(4), region(2)];

        state.use_polygon = false;

    end;

    if isfield(state.parameters, 'use_polygon')
        state.use_polygon = logical(state.parameters.use_polygon);
    end
    
    % TODO: testing
    bounding_box = rectangle_operation('scale', bounding_box, state.parameters.region_scale);
    
    image = image_create(image);

    state.parts = parts_create(state.parameters.parts.type);
    state.segmentation = segmentation_create(state.parameters.global);
    
    state.scaling =  1 / mean(bounding_box(3:4) / state.parameters.size); % TODO: this can probably be done better
    image = image_resize(image, state.scaling);
    bounding_box = round(bounding_box .* state.scaling);
    polygon_y = polygon_y .* state.scaling;
    polygon_x = polygon_x .* state.scaling;
    
    [gray, image] = image_convert(image, 'gray');

    % INITIALIZE MIDDLE LAYER: COLOR MODEL
    
    state.segmentation = segmentation_update(state.segmentation, image, bounding_box);
    cut_region = round(rectangle_operation('scale', bounding_box, state.parameters.global.region_scale));
    cut_image = image_crop(image, cut_region);
    
    probability = segmentation_generate(state.segmentation, cut_image, state.parameters.visualize.segmentation_generation);

    cosine_mask = hann(size(probability,1)) * hann(size(probability,2))';
    
    probability = probability .* cosine_mask;

    mask_region = rectangle_operation('offset', bounding_box, ...
        -cut_image.offset - 1);
        
    [~, threshold, quality] = segmentation_get_threshold(...
        probability, mask_region, state.parameters.global.purity, ...
        state.parameters.global.sufficiency, ...
            state.parameters.visualize.segmentation_threshold);

    mask = probability > threshold;

    mask = mask .* poly2mask(polygon_x - cut_region(1), polygon_y - cut_region(2), cut_region(4), cut_region(3));
    positions = segmentation_sample(cut_image, mask, probability, 60, state.parameters.visualize.parts_adding);

    % SETUP INITIAL SET OF PARTS
    [state.parts, added] = parts_add(state.parts, image, positions, repmat(state.parameters.parts.part_size, size(positions, 1), 2));
    state.parts.importance(added) = 0.5;
    state.parts.group(added) = 1;

    state.parts = parts_push(state.parts);    
    state.distances = pdist2(positions, positions);
    state.capacity = parts_size(state.parts);
    
    state.previous_image = image;
    
    template_region = rectangle_operation('scale', bounding_box, state.parameters.memory.rescale);    
    mask = imcrop(mask, rectangle_operation('offset', template_region, ...
            -cut_image.offset - 1));
    
    state.memory = memory_create(state.parameters.memory);
    center = rectangle_operation('getcenter', bounding_box);
    
    
    proposed_region = polygon_operation('setcenter', ...
                    polygon_operation('pack', polygon_x, polygon_y), 0, 0);
    state.memory = memory_update(state.memory, 'add', gray, center, mask, proposed_region);
    
    state.candidates = memory_create(state.parameters.memory);

    state.bounding_box = bounding_box;

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

    state.kalman_R = eye(2) * 0.1;
    state.kalman_Q = [0.333, 0, 0.5, 0; 0, 0.333, 0, 0.5; 0.5, 0, 1, 0; 0, 0.5, 0, 1];

    state.kalman_state = [rectangle_operation('getcenter', state.bounding_box) 0 0]';
    state.kalman_covariance = eye(4); 

    location = region;
    
    values = struct();
    
end
