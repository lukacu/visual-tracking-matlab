function [state, location, values] = tracker_lgt_update(state, image, varargin)

    values = struct();

    image = image_resize(image_create(image), state.scaling);
    
    [gray, image] = image_convert(image, 'gray');

    % CONSTELLATION OPTIMIZATION
    center = state.kalman_state(1:2)';
    velocity = state.kalman_state(3:4)';

    state.timer = timer_create();
    
    state.parts = parts_match_ce(image, state.parts, state.parameters.matching, center, velocity);
    
    state.timer = timer_push(state.timer);
    
    state.previous = image;

    position = wmean(state.parts.positions, state.parts.importance');
    [state.kalman_state, state.kalman_covariance] = kalman_update(state.kalman_F, state.kalman_H, state.kalman_Q, state.kalman_R, position', state.kalman_state, state.kalman_covariance);
        
    if ~state.parameters.guide.enabled
        location = determine_location(state);   
        state.previous = image;
        return;
    end
    
    responses = parts_responses(state.parts, 1:parts_size(state.parts), shiftdim(state.parts.positions', -1), image);           

    responses(isinf(responses) | isnan(responses)) = 0;
    
    new_importance = exp((responses - 1) * state.parameters.guide.similarity);
    new_importance = new_importance .* (1 ./ (1 + exp(( median(pdist2(state.parts.positions, state.parts.positions)) - state.parameters.size) * state.parameters.guide.distance)))';
    state.parts.importance = state.parameters.guide.persistence * state.parts.importance + (1-state.parameters.guide.persistence) * new_importance;

    if ~state.parameters.guide.enabled
        location = determine_location(state);
        state.previous = image;
        return;
    end
    
    % MERGING PARTS

    while (1)
        d = pdist2(state.parts.positions, state.parts.positions);
        for k = 1:parts_size(state.parts)
            overlap = d(:, k) < state.parameters.parts.merge;
            if sum(overlap) > 1
                state.parts = parts_merge(state.parts, image, overlap); 
                break;
            end;
        end;
        if k == parts_size(state.parts)
            break; 
        end;
    end;
    
    % REMOVING PARTS
    
    if parts_size(state.parts) > 3

        remove1 = state.parts.importance < state.parameters.parts.remove;

        [~, order] = sort(state.parts.importance); 
        remove2 = zeros(size(remove1));
        remove2(order(1:3)) = 1;

        state.parts = parts_remove(state.parts, remove1 & remove2);

    end;

    % UPDATING GLOBAL MODEL
    
    state.timer = timer_push(state.timer);
    
    state.modalities = modalities_update(state.modalities, image, state.kalman_state(1:2)', state.parts);

    state.parts = parts_push(state.parts);

    state.timer = timer_push(state.timer);
    
    % ADDING PARTS
    new = min(round(state.parts.capacity) - parts_size(state.parts) + 1, state.parameters.parts.max - parts_size(state.parts));

    if (new > 0)
    
        positions = round(bsxfun(@minus, state.parts.positions, state.kalman_state(1:2)' - (state.modalities.map_size) / 2));
        kernel = scalemax(gauss_kernel(eye(2) * state.parameters.modalities.mask), 1);
        mask = points2mask(positions(:, 1), positions(:, 2), state.modalities.map_size, state.modalities.map_size);
        mask = 1 - min(conv2(double(mask), kernel, 'same'), 1);

        npositions = modalities_sample(state.modalities, mask, new, kernel);
        
        state.modalities.sample_mask = mask;
        
        if (~isempty(npositions))
        
            npositions = bsxfun(@plus, npositions, state.kalman_state(1:2)');

            npositions = npositions(~any(pdist2(state.parts.positions, npositions) < 2), :);

            [state.parts, added] = parts_add(state.parts, image, npositions, repmat(state.parameters.parts.part_size, size(npositions, 1), 2));
            state.parts.importance(added) = 0.5;
            state.parts.group(added) = 1;
                       
        end;
 
    end;

    state.timer = timer_push(state.timer);
    
    state.parts.capacity = state.parameters.parts.persistence * state.parts.capacity + (1-state.parameters.parts.persistence) * parts_size(state.parts);

    fprintf('Status: %d parts\n', parts_size(state.parts));
        
    location = determine_location(state);
    state.previous = image;

end

function [location] = determine_location(state)

    if state.use_polygon

        positions = state.parts.positions;
        positions = positions(state.parts.importance > 0, :);
        hull = convhull(positions(:, 1), positions(:, 2));
        positions = positions(hull, :);            

        p = poly2bb(positions(:, 1), positions(:, 2))';
        region = p(:)';

    else
        region = parts_bounds(state.parts, state.parts.importance > 0);

        if (isempty(region))
            region = [0 0 0 0];
        end;
    
    end;

    location = region ./ state.scaling;

end
