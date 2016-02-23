function [parts, stats] = parts_match_icm(image1, image2, parts, parameters, velocity)
    previous_positions = parts.positions;

    stats = struct('iterations', 0);
    
    previous_gray = image_convert(image1, 'gray');
    next_gray = image_convert(image2, 'gray');
    window = parameters.flow.window;
    
    next_positions = cv.calcOpticalFlowPyrLK(previous_gray, ...
        next_gray, num2cell(previous_positions, 2), 'InitialFlow', ...
        num2cell(parts.positions, 2), 'WinSize', [window, window]);

    back_positions = cv.calcOpticalFlowPyrLK(next_gray, previous_gray, ...
        next_positions, 'WinSize', [window, window]);

    next_positions = reshape(cell2mat(next_positions), 2, size(previous_positions, 1))';
    back_positions = reshape(cell2mat(back_positions), 2, size(previous_positions, 1))';
    
    quality = exp(-sum((previous_positions - back_positions) .^ 2, 2));
    done = quality > parameters.flow.quality;

    %done(:) = 0; % - this disables flow
    
    parts.positions(done, :) = next_positions(done, :);
    parts.group(:) = 0;
    parts.group(done) = -1;
    % optimization (searching for optimal position)
    
    stats.flow = done;
    
    scope = 30;
    [X, Y] = meshgrid(linspace(-scope, scope, 31), linspace(-scope, scope, 31));

    responses = zeros(numel(X), numel(done));
    
    response_positions = parts.positions;
    
    if ~all(done)
        responses(:, ~done) = global_sample(image2, X(:), Y(:), parts.positions(~done, :), parts, find(~done));
    end;
    
    offsets = next_positions - previous_positions;
    
    for i = 1:length(done)        
        if (done(i))        
            responses(:, i) = exp(- ( (X(:) - offsets(i, 1)) .^ 2 + (Y(:) - offsets(i, 2)) .^ 2) .* parameters.flow.influence);
        end;
    end
    
    %CHANGE: response = sum(bsxfun(@times, responses, 1 ./ (sum(responses, 1) + eps)), 2);
    response = wmean(bsxfun(@times, responses, 1 ./ (sum(responses, 1) + eps))', parts.importance);
    
    response = reshape(response, size(X));
    
    motion_prior = exp(- ( (X - velocity(1)) .^ 2 +  (Y - velocity(2)) .^ 2) .* parameters.motion_prior);

    response = response .* motion_prior;

    H = fspecial('gaussian', [5, 5], 1);
    response = imfilter(response, H, 'replicate');
    [value, i] = max(response(:));
    
    
    M = [X(i), Y(i)];

    parts.positions(~done, :) = apply_transformation(parts.positions(~done, :), global_translate(M));

    iterations = parameters.iterations;

    apriori_positions = previous_positions;
    positions = parts.positions;
    
    if (~all(done))

        neighbours = cell(parts_size(parts), 1);

        switch parameters.neighborhood
            case 'delaunay'
                if (parts_size(parts) > 2)
                
                    tri = delaunay(parts.positions(:, 2), parts.positions(:, 1));
                    edges = zeros(parts_size(parts));

                    for i = 1:size(tri, 1)

                        for e = [tri(i, 1) tri(i, 2); tri(i, 2) tri(i, 3); tri(i, 3) tri(i, 1)]'
                            edges(e(1), e(2)) = i;
                            edges(e(2), e(1)) = i;
                        end;

                    end;
                
                else
                    edges = zeros(parts_size(parts));
                    
                end
            case 'proximity'
               
                radius = parameters.neighborhood_radius;
                
                edges = pdist2(apriori_positions, apriori_positions) < radius & ~eye(parts_size(parts));
                
        end;
        
        
        for i = 1:parts_size(parts)
            a = find(edges(i, :) ~= 0);
            if (length(a) < 3)
               neighbours{i} = [a i];
            else
               neighbours{i} = a;
            end
        end;

        new_positions = apriori_positions;

        kernel_sigma = parameters.sigma;
        
        history = zeros(numel(done), 2, iterations+1);
        steps = zeros(numel(done), 1);
        
        history(:, :, 1) = new_positions;
        
        part_weights = parts.importance';
        
        for i = 1:iterations

            offsets = positions - response_positions;
            
            for k = 1:numel(done)

                if (done(k))
                    continue;
                end;

                include = neighbours{k};

                kernel_position = offsets(k, :);

                if (numel(include) > 2)
                
                    A = wtransform(apriori_positions(include, :), positions(include, :), part_weights(include), 'similarity');
                    tr = A * [apriori_positions(k, :), 1]';
                    kernel_position = tr(1:2)' - response_positions(k, :);
                
                end
                
                weights = responses(:, k) .* exp(- ( (X(:) - kernel_position(1)) .^ 2 +  (Y(:) - kernel_position(2)) .^ 2) / kernel_sigma); 
                
                W = sum(weights);
                
                if W == 0
                    sum(sum(responses(:, k)))
                    x = kernel_position(1);
                    y = kernel_position(2);
                else
                    x = sum(X(:) .* weights) / W;
                    y = sum(Y(:) .* weights) / W;
                end;
                
                pos = [x, y] + response_positions(k, :);
                
                new_positions(k, :) = pos;  

            end;

            steps(~done) = steps(~done) + 1;
            history(:, :, i+1) = new_positions;
            
            done(~done) = sqrt(sum((positions(~done, :) - new_positions(~done, :)) .^ 2, 2)) < 0.5;
                      
            if (all(done))
                break;
            end;                         
            
            positions(~done, :) = new_positions(~done, :);

        end;

        parts.positions = positions;

        stats.done = done;
        
        stats.iterations = i;
        
%         sfigure(6);
%         imshow(next_gray);
%         hold on;
%         for i = 1:numel(done)        
%             plot(squeeze(history(i, 1, 1:steps(i)+1)), squeeze(history(i, 2, 1:steps(i)+1)), 'r');
%             if steps(i) > 0
%             plot(squeeze(history(i, 1, end)), squeeze(history(i, 2, end)), 'bo');
%             end
%         end
%         hold off;        
        
    end;
    
    
end

function A = global_translate(parameters)

	A = [1 0, parameters(1);
        0, 1, parameters(2);
        0 0 1];

end

function [responses] = global_sample(image, x, y, positions, parts, indices)

    P = [x, y];
   
    samples = numel(x);
    
    sampled_positions = zeros(samples, 2, numel(indices));
    
    for k = 1:samples
        A = global_translate(P(k, :));

        sampled_positions(k, :, :) = apply_transformation(positions, A)';

    end;

    responses = parts_responses(parts, indices, sampled_positions, image)';
    responses(isnan(responses)) = 0;
    
end
