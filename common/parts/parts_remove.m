function [parts] = parts_remove(parts, indices)

    if islogical(indices)
        if numel(indices) ~= size(parts.positions, 1)
            warning('Incorrect indices');
            return;
        end;
        mask = ~indices(:);
    else            
        mask = true(size(parts.positions, 1), 1);
        mask(indices(indices > 0 && indices <= size(parts.positions, 1))) = false;
    end;

    parts.positions = parts.positions(mask, :);
    parts.sizes =parts.sizes(mask, :);
    parts.importance = parts.importance(mask);
    parts.group = parts.group(mask);
    
    parts.properties = parts.properties(mask);
    parts.text = parts.text(mask);
    parts.trajectories = parts.trajectories(mask);

    parts.data = parts.data(mask);
    
end
