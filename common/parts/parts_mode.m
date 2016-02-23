function [region, inliers] = parts_mode(parts, initial, iterations)

region = initial;
inliers = [];

for i = 1:iterations
    
    [~, ~, inliers] = compute_coverage(parts.positions, region);

    if ~any(inliers)
        break;
    end;
    
    center = wmean(parts.positions(inliers, :), parts.importance(inliers));
    
    difference = sqrt(sum((center - rectangle_operation('getcenter', region)) .^ 2));

    if difference < 1
        
        %i
        
        break; 
    end
    
    region = rectangle_operation('setcenter', region, center);
    
end

end

function [contained, density, mask] = compute_coverage(positions, region)

mask = (positions(:, 1) >= region(1) & positions(:, 1) <= region(1) + region(3)) & ...
        (positions(:, 2) >= region(2) & positions(:, 2) <= region(2) + region(4));

contained = sum(mask) / numel(mask);
    
density = sum(mask) / (region(3) * region(4));

end
