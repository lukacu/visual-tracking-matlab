function [mask] = parts_mask(parts, indices, size, kernel)

if isempty(indices)
    indices = 1:parts_size(parts);
end;

if islogical(kernel)
    M = kernel;
else
    radius = kernel;   
    M = logical(fspecial('disk', radius));
end;

%positions = round(bsxfun(@minus, definite, context.position - (context.map_size) / 2));

mask = points2mask(parts.positions(indices, 1), parts.positions(indices, 2), size(1), size(2));
mask = imdilate(mask, M);