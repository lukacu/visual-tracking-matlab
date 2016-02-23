function [contained, density, mask] = compute_coverage(positions, region)

mask = (positions(:, 1) >= region(1) & positions(:, 1) <= region(1) + region(3)) & ...
        (positions(:, 2) >= region(2) & positions(:, 2) <= region(2) + region(4));

contained = sum(mask) / numel(mask);
    
density = sum(mask) / (region(3) * region(4));