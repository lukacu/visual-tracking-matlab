function [parts, indices] = parts_merge(parts, image, indices)

    if islogical(indices)
        if numel(indices) ~= size(parts.positions, 1)
            warning('Incorrect indices');
            return;
        end;
        mask = indices(:);
    else            
        mask = true(size(parts.positions, 1), 1);
        mask(indices(indices > 0 && indices <= size(parts.positions, 1))) = false;
    end;

    if (sum(mask) < 2)
        return;
    end;
                
    importance = parts.importance(mask);

	new_position = wmean(parts.positions(mask, :), importance);
	new_size = wmean(parts.sizes(mask, :), importance);

    [parts, indices] = parts_add(parts_remove(parts, indices), image, new_position, new_size);
    
	parts.importance(indices) = max(importance);

end
