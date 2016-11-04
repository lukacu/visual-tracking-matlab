function [modalities] = modalities_update(modalities, image, position, parts)

    modalities.sample_mask = ones(modalities.map_size, ...
		modalities.map_size);

    context.map_size = modalities.map_size;
    context.position = position;
    context.image = image;
    context.parts = parts;

    if modalities.shape.parameters.enabled
        modalities.shape = update_shape(modalities.shape, context);
    end;
    if modalities.color.parameters.enabled
        modalities.color = update_color(modalities.color, context);
    end;
    if modalities.motion.parameters.enabled
        modalities.motion = update_motion(modalities.motion, context);
    end;

    modalities.map = ones(modalities.map_size, modalities.map_size);
    usable = false;

    if modalities.color.parameters.enabled && ~isempty(modalities.color.map)
        modalities.map = modalities.map .* modalities.color.map;
        usable = true;
    end;

    if modalities.motion.parameters.enabled && ~isempty(modalities.motion.map)
        modalities.map = modalities.map .* modalities.motion.map;
        usable = true;
    end;

    if modalities.shape.parameters.enabled && ~isempty(modalities.shape.map)
        modalities.map = modalities.map .* modalities.shape.map;
        usable = true;
    end;

    if ~usable
        modalities.map = [];
    end
end

function [shape] = update_shape(shape, context)

    p = shape.parameters.persistence;
    radius = shape.parameters.expand;

    switch shape.parameters.model

        case 'rectangle'

            if (parts_size(context.parts) < 3)
                return;
            end;

            if (isempty(shape.shape))
                shape.shape = parts_bounds(context.parts);
            end;

            start_center = wmean(context.parts.positions, context.parts.importance);
            start_region = rectangle_operation('setcenter', rectangle_operation('expand', shape.shape, 5), start_center);

            [~, inliers] = parts_mode(context.parts, start_region, 10);
            region = parts_bounds(context.parts, inliers);
            shape.shape(3:4) = p * shape.shape(3:4) + (1 - p) * region(3:4);
            shape.shape(1:2) = region(1:2);

            [x, y] = rect2points(shape.shape);

            x = x - context.position(1) + context.map_size / 2;
            y = y - context.position(2) + context.map_size / 2;

            shape.map = normalize(poly2mask(x, y, context.map_size, context.map_size));

        case 'additive'

            if (isempty(shape.shape))
                shape.shape = zeros(context.map_size, context.map_size);
            end;

            positions = context.parts.positions(context.parts.importance >= 0.5, :);

            if (size(positions, 1) < 3)
                return;
            end;

            hull = convhull(positions(:, 1), positions(:, 2));
            positions = positions(hull, :);

            x = positions(:, 1) - context.position(1) + context.map_size / 2;
            y = positions(:, 2) - context.position(2) + context.map_size / 2;

            origin = mean([x, y], 1);
            vector = [x, y] - ones(size(x, 1), 1) * origin;
            len = sqrt(sum(vector .^2, 2));
            scale = (len + radius) ./ len;
            expanded =  ones(size(x, 1), 1) * origin + vector .* [scale , scale];

            new_shape = poly2mask(x, y, context.map_size, context.map_size) * 0.3 ...
                + poly2mask(expanded(:, 1), expanded(:,2), context.map_size, context.map_size) * 0.7;

            shape.shape = scalemax(p * shape.shape + (1 - p) * new_shape, 1);

            shape.map = normalize(shape.shape);

    end;

end

function [color] = update_color(color, context)

    bins = color.parameters.bins;

    definite = context.parts.positions(context.parts.importance >= 0.5, :);

    if strcmp(color.parameters.color_space,'hsv')
        imagecs = image_convert(context.image, 'hsv') .* 255;
        edges = {linspace(0,256,bins(1)+1), linspace(0,256,bins(2)+1), linspace(0,256,bins(3)+1)};
    elseif strcmp(color.parameters.color_space, 'rgb')
        imagecs = image_convert(context.image, 'rgb');
        edges = {linspace(0,256,bins(1)+1), linspace(0,256,bins(2)+1), linspace(0,256,bins(3)+1)};
    end;

    imagecut = zeros(context.map_size, context.map_size, 3);
    offset = -int32(context.position - (context.map_size) / 2);
    imagecut = patch_operation(imagecut, imagecs, offset(1), offset(2), '=');

    radius = color.parameters.fg_sampling;
    M = logical(cone_kernel(color.parameters.fg_sampling * 2 + 1, 1, 0, radius, radius));

    positions = round(bsxfun(@minus, definite, context.position - (context.map_size) / 2));

    mask = points2mask(positions(:, 1), positions(:, 2), context.map_size, context.map_size);
    mask = imdilate(mask, M);

    if any(mask(:)) > 0
        fgappearance = normalize(cv.calcHist(imagecut, edges, 'Mask', mask));
        color.foreground = color.parameters.fg_persistence * color.foreground + (1 - color.parameters.fg_persistence) * fgappearance;
    end;

    spacing = color.parameters.bg_spacing;
    width = color.parameters.bg_sampling;

    positions = context.parts.positions;

    try

        hull = convhull(positions(:, 1), positions(:, 2));
        positions = positions(hull, :);

        x = positions(:, 1) - context.position(1) + context.map_size / 2;
        y = positions(:, 2) - context.position(2) + context.map_size / 2;

        segmentation = poly2mask(x, y, context.map_size, context.map_size);
        mask = imdilate(segmentation, ones(spacing + width)) & ~imdilate(segmentation, ones(spacing));

        p = (sum(sum(segmentation)) / numel(segmentation));

        if p > 0.01
            bgappearance = normalize(cv.calcHist(imagecut, edges, 'Mask', mask) + 1);
            color.background = color.parameters.bg_persistence * (color.background) + (1 - color.parameters.bg_persistence) * bgappearance;
        end;

    catch
        % Probably a convex hull error. Do not update background in this case.
    end;

    if color.parameters.regularize > 0

        foreground_map = cv.calcBackProject(imagecut, color.foreground, edges);
        background_map = cv.calcBackProject(imagecut, color.background, edges);

        sum_map = foreground_map + background_map + eps ;
        foreground_map = foreground_map./sum_map ;
        background_map = background_map./sum_map ;

		regularize = color.parameters.regularize;
        H = fspecial('gaussian', [15, 15], regularize);
        foreground_map = imfilter(foreground_map, H, 'replicate');
        background_map = imfilter(background_map, H, 'replicate');

        p = color.parameters.prior;
        color.map = normalize(p .* (foreground_map) ./ ((p .* foreground_map + (1 - p) .* background_map)));

    else

        p = color.parameters.prior;
        model = p .* (color.foreground) ./ ((p .* color.foreground + (1 - p) .* color.background));

        color.map = normalize(cv.calcBackProject(imagecut, model, edges));

    end;

end

function [motion] = update_motion(motion, context)

    if (~isfield(motion, 'previous_image'))
        motion.previous_position = context.position;
        motion.previous_image = image_convert(context.image, 'gray');
        motion.map = normalize(ones(context.map_size));
        return;
    end;

    cur_positions = context.parts.positions;
    pre_positions = parts_history(context.parts, 1);

    indices = (context.parts.importance >= 0.5) & all(~isnan(cur_positions), 2) & all(~isnan(pre_positions), 2);

    move = pre_positions(indices, :) - cur_positions(indices, :);

    object_move = wmean(move, context.parts.importance(indices)');

    offset1 = - context.position - object_move + context.map_size / 2;
    offset2 = - context.position + context.map_size / 2;

    gray1 = uint8(patch_operation(zeros(context.map_size), motion.previous_image, offset1(1), offset1(2), '='));
    gray2 = uint8(patch_operation(zeros(context.map_size), image_convert(context.image, 'gray'), offset2(1), offset2(2), '='));

    radius = 7;
    bordermask = false(size(gray2));
    bordermask(radius+1:end-radius, radius+1:end-radius) = 1;

    corners = cv.cornerHarris(gray2, 'KSize', 1); % OpenCV 2.4 : AppertureSize
    corners = ((ordfilt2(corners, radius * radius, true(radius))) == corners) & (corners > eps) & bordermask;

    [y, x] = find(corners);

    if ~isempty(y)

        positions_origin = [x, y];

        [positions_flow, status] = cv.calcOpticalFlowPyrLK(gray2, gray1, num2cell(positions_origin, 2), 'WinSize', [motion.parameters.lk_size, motion.parameters.lk_size]);
        positions_flow = reshape(cell2mat(positions_flow), 2, size(positions_origin, 1))';

        flow = positions_flow - positions_origin;

        similarity = exp(-sqrt(sum(flow .^ 2, 2)) .* motion.parameters.damping);

        result = zeros(size(gray1));
        similarity(~status) = 0;

        result(corners > 0) = similarity;

        result = conv2(result, gauss_kernel(eye(2) * 90), 'same');
        result = normalize(result)  .* 0.99 + 0.01 * 1 / numel(result); % A very small uniform component

    else
        result = ones(context.map_size);
    end

    if (isempty(motion.map))
        motion.map = ones(size(result));
    end;

    motion.map = motion.parameters.persistence * motion.map + ((1 - motion.parameters.persistence) * result);
    motion.map = normalize(motion.map);

    motion.previous_position = context.position;
    motion.previous_image = image_convert(context.image, 'gray');

end

