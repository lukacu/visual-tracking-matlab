function [positions] = parts_history(parts, shift)
            
    positions = nan(numel(parts.properties), 2);

    shift = shift - 1;
    
    for i = 1:numel(parts.properties)
        age = size(parts.trajectories{i}, 1);
        if (age <= shift)
            continue;
        end;

        positions(i, :) = parts.trajectories{i}(age - shift, :);
    end;


