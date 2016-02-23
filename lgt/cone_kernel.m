function [cone] = cone_kernel(fsize, from, to, radius1, radius2, center)

cone = zeros(fsize);

[a, b] = size(cone);

if nargin < 6
    center = round([a, b] ./ 2);
end;

if nargin < 4
    radius1 = min(min([a, b], abs([a, b] - center)));
    radius2 = radius1 + 1;
end;

if nargin < 5
    radius2 = radius1;
    radius1 = 0;
end;

rd = radius2 - radius1;

if (rd == 0)
    rd = 1;
end;

k = (from - to) / rd;

for i = 1 :  a
    for j = 1 : b
        d = sqrt(sum(([i, j] - center) .^ 2));
        cone(i, j) = to + max(0, min(rd - d + radius1, rd)) * k;
    end;
end;
