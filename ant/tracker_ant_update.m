function [state, location, values] = tracker_ant_update(state, image, varargin)

    image = image_resize(image_create(image), state.scaling);
            
    [gray, image] = image_convert(image, 'gray');

    % CONSTELLATION OPTIMIZATION

    values = struct();
    
    state.parts_candidate = [];
    state.bounding_box = rectangle_operation('setcenter', state.bounding_box, (state.kalman_state(3:4) + state.kalman_state(1:2))');

    state.timer = timer_create();
    
    if parts_size(state.parts) > 0
            
        [parts, stats] = parts_match_icm(state.previous_image, image, state.parts, state.parameters.matching, state.kalman_state(3:4)');     

        state.parts = parts_push(parts);

        responses = parts_responses(state.parts, 1:parts_size(state.parts), shiftdim(state.parts.positions', -1), image);

        responses(isinf(responses) | isnan(responses)) = 0;

        values.parts_max_response = max(responses);
        values.parts_min_response = min(responses);
        
        new_importance = exp((responses - 1) * state.parameters.parts.similarity);
        state.parts.importance = state.parameters.guide.persistence * state.parts.importance + (1 - state.parameters.guide.persistence) * new_importance;

        values.parts_iterations = mean(stats.iterations);
        values.parts_flow = sum(stats.flow) / parts_size(state.parts);        
        
        start_center = wmean(state.parts.positions, state.parts.importance);
        start_region = rectangle_operation('setcenter', rectangle_operation('expand', state.bounding_box, ...
            state.parameters.guide.size_expand), start_center);

        [state.parts_candidate, inliers] = parts_mode(state.parts, start_region, 10);

        state.parts_candidate = parts_bounds(state.parts, inliers);

        state.parts.importance(~inliers) = state.parts.importance(~inliers) * 0.1;    

    end;
    
    state.timer = timer_push(state.timer);
    
    state.previous_image = image;
    
    search_scope = min(state.bounding_box(3), state.bounding_box(4)) * 2; % TODO
    search_region = rectangle_operation('setcenter', [0, 0, search_scope, search_scope], rectangle_operation('getcenter', state.bounding_box)); % Center in motion prediction ?
    
    [template_regions, template_scores] = memory_match(state.memory, gray, search_region, state.parameters.visualize.template_match);

    % TODO: test removing this!!
    template_inclusion = calculate_inclusion(template_regions, state.bounding_box);

    [template_match_score, match_index] = max(template_scores);  
    state.template_candidate = template_regions(match_index, :);
    state.template_candidate = template_regions(match_index, :);

    templates_included = (template_inclusion > state.parameters.memory.overlap);
    template_scores(~templates_included) = 0;
    [template_guide_score, guide_index] = max(template_scores);  

    values.template_guide_score = template_guide_score;
    
    state.timer = timer_push(state.timer);
    
    if template_match_score > state.parameters.memory.match
        
        values.selected_template = match_index;
        
        mode = 'match';
        state.mode = 3;
        values.mode = 3;
        
        region = state.template_candidate;

        sample_region = state.template_candidate;

        add_parts = state.parameters.parts.increase;
        
    elseif template_guide_score > state.parameters.memory.guide
        
        state.template_candidate = template_regions(guide_index, :);

        values.selected_template = guide_index;
        
        mode = 'guided';
        state.mode = 2;
        values.mode = 2;

        region = state.parts_candidate;

        sample_region = state.template_candidate;
        %sample_region = state.parts_candidate;

        add_parts = state.parameters.parts.increase;
        
    elseif ~isempty(state.parts_candidate)
       
        mode = 'parts';
        state.mode = 1;
        values.mode = 1;
        
        region = state.parts_candidate;
        sample_region = region;

        add_parts = state.parameters.parts.increase;
        
    else
        
        state.parts_candidate = [0, 0, 1, 1];
        mode = 'blind';
        state.mode = 0;
        values.mode = 0;
        
        region = state.bounding_box;

        sample_region = [];

        add_parts = 0;
        
    end
    
    state.status_message = sprintf('Tracking: %s', mode);
    
    % SEGMENTATION ESTIMATION
    
    if ~isempty(sample_region)
    
        cut_region = round(rectangle_operation('scale', sample_region, state.parameters.global.region_scale));

        cut_image = image_crop(image, cut_region);
        probability = segmentation_generate(state.segmentation, cut_image, ...
            state.parameters.visualize.segmentation_generation);

        state.segmentation.probability = probability;
        state.cut_region = cut_region;
        
    end;
    
%     cosine_mask = hann(size(probability,1)) * hann(size(probability,2))';    
%     probability = probability .* cosine_mask;    
%     
    
    %map = regions_to_map(template_regions, template_scores, cut_image.offset, ones(size(probability)));
    %sfigure(10); imagesc(map);
    %probability = probability .* map;
    
    % REMOVING AND ADDING PARTS

    if parts_size(state.parts) > 0
    
        discard = state.parts.importance < state.parameters.parts.remove;

        distances = pdist2(state.parts.positions, state.parts.positions);
        importance = repmat(state.parts.importance, 1, parts_size(state.parts));
        importance(discard, :) = 0;
        importance(distances > state.parameters.parts.merge) = 0;

        [V, I] = max(importance);
        merge = (I ~= 1:numel(I) & V > 0)';
        remove = discard | merge;

        values.parts_remove = sum(remove);

%         if (values.parts_remove > 0)
%            merge
%            remove 
%            state.parts.importance
%         end
        
        state.parts = parts_remove(state.parts, remove);

    else
        values.parts_remove = 0;
        
    end;

    values.parts_add = 0;
    values.segmentation_threshold = 1;
    values.segmentation_quality = 0;
    
    if ~isempty(sample_region)
    
        sample_region = round(sample_region);

        mask_sample_region = rectangle_operation('offset', sample_region, ...
            -cut_image.offset - 1);
        
        [segment_probability, values.segmentation_threshold, values.segmentation_quality] ...
            = segmentation_get_threshold(...
            probability, mask_sample_region, state.parameters.global.purity, ...
            state.parameters.global.sufficiency, ...
            state.parameters.visualize.segmentation_threshold);

        mask = probability > values.segmentation_threshold;
        
        state.mask = mask;
%maskpre = mask;
        
         mask = bwmorph(mask, 'close', 1);
         mask = bwmorph(mask, 'open', 1);
        
        [labels, count] = bwlabel(mask);
        safe = imcrop(labels, round(rectangle_operation('scale', mask_sample_region, 0.8)));
        safe = safe(safe > 0);
        inliers = unique(safe);
        elements = histc(safe(:), 1:count);
       
        oksize = (elements(inliers) ./ numel(safe)) > 0.3;
        mask = ismember(labels, inliers(inliers > 0 & oksize));
        
%         mask2 = segmentation_process_mask(probability, 20);
%         sfigure(13);
%         subplot(1, 4, 1); imshow(image_convert(cut_image, 'rgb'));
%         subplot(1, 4, 2); imagesc(maskpre);
%         subplot(1, 4, 3); imagesc(mask);
%         subplot(1, 4, 4); imagesc(probability);
        
        %sample_image = image_crop(image, sample_region);

        [height, width] = image_size(cut_image);
        
        positions = round(bsxfun(@minus, state.parts.positions, cut_region(1:2)));  

        sample_mask = mask;
        if ~isempty(positions)
            [X, Y] = meshgrid(0:(width-1), 0:(height-1));
            sample_mask = sample_mask & ~reshape(min(pdist2([X(:), Y(:)], positions,'chebychev'), [], 2) < state.parameters.global.mask / 2, size(X));  
        end;
        
        [npositions, nweights] = segmentation_sample(cut_image, sample_mask, probability, add_parts, state.parameters.visualize.parts_adding);
        
        values.parts_add = numel(nweights);

        if (~isempty(npositions))

            [state.parts, added, nvalid] = parts_add(state.parts, image, npositions, repmat(state.parameters.parts.part_size, size(npositions, 1), 2));
            state.parts.importance(added) = nweights(nvalid);
            state.parts.group(added) = 1;
                       
        end;

        values.parts_add = sum(nweights);
        
    else
        
        values.parts_add = 0;
        
    end;

    state.timer = timer_push(state.timer);
    
    % UPDATING GLOBAL MODEL
    
    candidates_accept_frequency = state.parameters.memory.candidates_frequency;
    candidates_overlap = state.parameters.memory.candidates_overlap;
    candidates_reject = state.parameters.memory.candidates_reject;
    
    state.memory = memory_update(state.memory, 'age'); 
    state.candidates = memory_update(state.candidates, 'age'); 
    
    if ~isempty(region)

        values.parts_contained = compute_coverage(state.parts.positions, region);
        
        % Matching candidates   
        [candidate_regions, candidate_scores] = memory_match(state.candidates, gray, region);

        for i = 1:numel(candidate_scores)

            overlap = calculate_overlap(candidate_regions(i, :), region);
            
            if (candidate_scores(i) < state.parameters.memory.guide || overlap < candidates_overlap)
                candidate_scores(i) = 0;
                continue;
            end

        end

        good_candidates = candidate_scores > 0;
        
        state.candidates = memory_update(state.candidates, 'update', gray, good_candidates); 

        add_candidate = numel(candidate_scores) == 0 || max(candidate_scores(:)) < state.parameters.memory.guide;

        % If template used enough
        if state.candidates.frequency(good_candidates) > candidates_accept_frequency

            % Move candidate template to master set
            [state.candidates, candidates] = memory_remove(state.candidates, good_candidates);
            state.memory = memory_update(state.memory, 'insert', candidates); 

        end
        
        redundant_candidates = state.candidates.age > candidates_reject;
        [state.candidates, ~] = memory_remove(state.candidates, redundant_candidates);

        switch mode
            case 'match'
                state.memory = memory_update(state.memory, 'update', gray, match_index); 
                state.segmentation = segmentation_update(state.segmentation, image, region, 'background');
                state.segmentation = segmentation_update(state.segmentation, image, parts_mask(state.parts, state.parts.importance > 0.5, image_size(image), 3), 'foreground');
                
                estimate_certanty = state.parameters.motion.match;

            case 'guided'
                
                state.memory = memory_update(state.memory, 'update', gray, guide_index); 
                state.segmentation = segmentation_update(state.segmentation, image, sample_region, 'background');
                state.segmentation = segmentation_update(state.segmentation, image, parts_mask(state.parts, state.parts.importance > 0.5, image_size(image), 3), 'foreground');
                
                estimate_certanty = state.parameters.motion.guide;

                candidate_initial_region = rectangle_operation('offset', ...
                    sample_region, -cut_region(1:2));

                positions = round(bsxfun(@minus, state.parts.positions, cut_region(1:2)));  
                [~, ~, inliers] = compute_coverage(positions, candidate_initial_region);    

                prior = sum(inliers) * (state.parameters.parts.part_size .^ 2) * state.parameters.memory.size_factor;

                prior = max(prior, 0.5 * candidate_initial_region(3) * candidate_initial_region(4));

                candidate_region = fit_rectangle(mask, ...
                        candidate_initial_region, 100, prior, state.parameters.memory.size_influence);

                if ~isempty(candidate_region) && add_candidate

                        candidate_region = rectangle_operation('offset', ...
                            candidate_region, cut_region(1:2));

                        overlap = calculate_overlap(candidate_region, region);

                        if (overlap > candidates_overlap)

                            candidate_mask = normalize(patch_operation(...
                                ones(candidate_region(4), candidate_region(3)), ...
                                probability, -candidate_region(1), ...
                                -candidate_region(2), '*'));

                            candidate_center = rectangle_operation('getcenter', ...
                                candidate_region);

                            candidate_mask = candidate_mask ./ max(candidate_mask(:));

                            proposed_region = polygon_operation('setcenter', ...
                                polygon_operation('convert', determine_location( state )), 0, 0);

                            state.candidates = memory_update(state.candidates, 'add', gray, candidate_center, candidate_mask, proposed_region);   
                        end
                end

            case 'parts'

                [~, inliers] = parts_mode(state.parts, region, 10);
                region = parts_bounds(state.parts, inliers);

                state.segmentation = segmentation_update(state.segmentation, image, region, 'background');
                
                
                estimate_certanty = state.parameters.motion.parts;

            case 'blind'
                
                estimate_certanty = state.parameters.motion.blind;

        end

    end;

    if ~isempty(state.parts_candidate)
        values.parts_coverage = parts_size(state.parts) * (state.parameters.parts.part_size .^ 2);

        area = state.parts_candidate(3) * state.parts_candidate(4); 
        values.parts_percentage = parts_size(state.parts) * (state.parameters.parts.part_size .^ 2) / area;

        values.parts_overlap = calculate_overlap(state.parts_candidate, state.bounding_box);
    
    end;
    
    
    values.templates_count = numel(state.memory.age);
    values.candidates_count = numel(state.candidates.age);
    
    % UPDATING MOTION MODEL
    
    if (isempty(region)) % Target lost, using motion model
        
        region = state.bounding_box;
        state.kalman_R = eye(2) ./ 0.0001;
        
    else

        state.kalman_R = eye(2) ./ estimate_certanty;
        persistence = state.parameters.size_persistence;
        state.bounding_box(3:4) = persistence * state.bounding_box(3:4) + (1 - persistence) * region(3:4);
        
    end;

    values.color_similarity = sum(sqrt(normalize(state.segmentation.foreground(:)) .* normalize(state.segmentation.background(:))));
    
    center = rectangle_operation('getcenter', region);
    [state.kalman_state, state.kalman_covariance] = kalman_update(state.kalman_F, state.kalman_H, state.kalman_Q, state.kalman_R, center', state.kalman_state, state.kalman_covariance);

    location = double(rectangle_operation('setcenter', state.bounding_box, state.kalman_state(1:2)') ./ state.scaling);
    if state.use_polygon
        location = rect2points(location)';
        location = location(:);
    end
    
%     if strcmp(mode, 'match')
%         location = polygon_operation('setcenter', ...
%                     state.memory.instances{match_index}.region, state.kalman_state(1:2)) ./ state.scaling;
%     else
%         location = determine_location(state) ./ state.scaling;
%     end

    state.timer = timer_push(state.timer);

    values.parts_count = parts_size(state.parts);
    
    fprintf('Status: %d parts\n', parts_size(state.parts));

end

function [overlap] = calculate_inclusion(T1, T2)
len1 = size(T1, 1);
len2 = size(T2, 1);

if len1 ~= len2
   if len1 == 1
      T1 = repmat(T1, len2, 1);
   end
   if len2 == 1
      T2 = repmat(T2, len1, 1);
   end    
end

hrzInt = min(T1(:, 1) + T1(:, 3), T2(:, 1) + T2(:, 3)) - max(T1(:, 1), T2(:, 1));
hrzInt = max(0,hrzInt);
vrtInt = min(T1(:, 2) + T1(:, 4), T2(:, 2) + T2(:, 4)) - max(T1(:, 2), T2(:, 2));
vrtInt = max(0,vrtInt);
intersection = hrzInt .* vrtInt;

area = T2(:, 3) .* T2(:, 4);

overlap = intersection ./ area;

end

function region = determine_location( state )
   
    if state.use_polygon && parts_size(state.parts) > 2

        positions = state.parts.positions;
        
        hull = convhull(positions(:, 1), positions(:, 2));
        positions = positions(hull, :);   
        sizes = state.parts.sizes(hull, :);
        
        % get transformation
        C = cov(positions) ;
        Mu = mean(positions) ;

        positions = bsxfun(@minus, positions, Mu) ;

        [U,S,~] = svd(C) ;

        p = min(S(1,1), S(2,2)) / max(S(1,1), S(2,2));

        if (p > 0.6) 
            U = eye(2);
        end;
        
        xy2 = positions * U ;

        minx = min(xy2(:,1) - sizes(:, 1) / 2) ; maxx = max(xy2(:,1) + sizes(:, 1) / 2) ;
        miny = min(xy2(:,2) - sizes(:, 2) / 2) ; maxy = max(xy2(:,2) + sizes(:, 2) / 2) ;
        p2 = [minx, miny; maxx, miny; maxx, maxy; minx, maxy] ;
        region = bsxfun(@plus, p2*U', Mu) ;

        region = polygon_operation('pack', region(:, 1), region(:, 2));
        
    else
    
        region = parts_bounds(state.parts);

        if (isempty(region))
            region = [0 0 0 0];
        end;
    
    end

end

