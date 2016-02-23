function [parts] = parts_match_ce(image, parts, parameters, center, velocity)

    parts.positions = bsxfun(@plus, parts.positions, velocity); 

    % optimization (searching for optimal position)
    gM = parameters.global_move;
    gR = parameters.global_rotate;
    gS = parameters.global_scale;
    iterations = parameters.iterations;

    samples_min = parameters.global_samples_min;
    samples_max = parameters.global_samples_max;
    elite = parameters.global_elite;
    
    G = [gM gM gR gS gS]' * ones(1, 5) .* eye(5);
    M = [0 0 0 1 1];

    gamma_low = 0;
    gamma_high = 0;
    
    average_samples = 0;
    
    response = zeros(samples_max, 1);
    P = zeros(samples_max, 5);
    
    for i = 1:iterations

        samples = samples_min;
        
        [tresponse, tP] = global_sample(image, M, G, samples, parts.positions, center, parts); 

        response(1:samples, :) = tresponse;
        P(1:samples, :) = tP;
        
        while 1
            [s, important] = sort(response(1:samples, :), 'descend');

            if (gamma_low < s(elite) || gamma_high < s(1))
                gamma_low = s(elite);
                gamma_high = s(1);
                break;

            end;
            
            [tresponse, tP] = global_sample(image, M, G, 10, parts.positions, center, parts); 
            
            response(samples+1:samples+10, :) = tresponse;
            P(samples+1:samples+10, :) = tP;
            samples = samples + 10;
                                
            if (samples > 300)
                break;
            end;
      
        end;
        
        average_samples = average_samples + samples;
        G = wcov(P(important(1:elite), :), response(important(1:elite)));
        M = wmean(P(important(1:elite), :), response(important(1:elite)));
        
%         if (det(G) < 1e-6)
%         	break;
%         end;
        
    end;

    parts.positions = apply_transformation(parts.positions, global_transform(M, center));
    apriori_positions = parts.positions;

    tweights = parts.importance;
    covariance = zeros(2, 2, parts_size(parts)); %#ok<*PROP>
    done = false(parts_size(parts), 1);
    
    for k = 1:parts_size(parts)
        covariance(:,:,k) = eye(2) .* parameters.local_radius;
    end;

    if (parts_size(parts) > 3)

        neighbours = cell(parts_size(parts), 1);

        switch parameters.neighborhood
            case 'delaunay'
                tri = delaunay(parts.positions(:, 2), parts.positions(:, 1));
                edges = zeros(parts_size(parts));

                for i = 1:size(tri, 1)

                    for e = [tri(i, 1) tri(i, 2); tri(i, 2) tri(i, 3); tri(i, 3) tri(i, 1)]'
                        edges(e(1), e(2)) = i;
                        edges(e(2), e(1)) = i;
                    end;

                end;
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

        positions = apriori_positions;
        new_positions = apriori_positions;

        samples = parameters.local_samples;

        rigidity = parameters.rigidity;
        visual = parameters.visual;

        pick = parameters.local_elite;

        for i = 1:iterations

            for k = 1:parts_size(parts)

                include = neighbours{k};
                
                if (done(k))
                    continue;
                end;

                P = sample_gaussian(positions(k, 1:2), covariance(:,:, k), samples);

                r = parts_responses(parts, k, P, image);
                r(isnan(r)) = 0;
                
                values = exp( (r-1) * visual );

                P = P(~isinf(values), :);
                values = values(~isinf(values));

                if (numel(include) > 2)
                
                    A = wtransform(apriori_positions(include, :), positions(include, :), tweights(include)');

                    tr = A * [apriori_positions(k, :), 1]';

                    importance = values' .* exp(-pdist2(P, tr(1:2)') * rigidity) ;
                
                else
                    
                    importance = values';
                end
                
                [s, important] = sort(importance, 'descend');

                if (s(1) == 0) % all the elite samples have importance 0
                    tweights(k) = eps;
                    done(k) = 1;
                    pos = positions(k, 1:2);
                else
                    covariance(:, :, k) = wcov(P(important(1:pick), :), importance(important(1:pick)));
                    pos = wmean(P(important(1:pick), :), importance(important(1:pick)));
                end;

                new_positions(k, :) = pos;  

            end;

            positions = new_positions;

            for j = 1:parts_size(parts)
                if (det(covariance(:,:,j)) < 0.0001)
                    done(j) = 1;
                end;
            end;

            if (done)
                break;
            end;                         
        end;

        parts.positions = positions;
    
    end;
    
end

function A = global_transform(parameters, pivot)

    c = cos(parameters(3));
    s = sin(parameters(3));

	A = [c -s, parameters(1) + pivot(1) + s * pivot(2) - c * pivot(1);
        s, c, parameters(2) + pivot(2) - s * pivot(1) - c * pivot(2);
        0 0 1];

end

function [response, P] = global_sample(image, M, G, samples, positions, position, parts)

    if isempty(G)    
        P = M;
        samples = 1;
    else
        P = sample_gaussian(M, G, samples);
    end;
    
    sampled_positions = zeros(samples, 2, parts_size(parts));
    
    for k = 1:samples
        A = global_transform(P(k, :), position);

        sampled_positions(k, :, :) = apply_transformation(positions, A)';

    end;
    
    values = parts_responses(parts, [], sampled_positions, image);

    response = zeros(samples, 1);

    values(isnan(values)) = 0;
    
    for k = 1:samples
        response(k) = wmean(values(:, k), parts.importance');
    end;

end