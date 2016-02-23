function [shift] = compute_shift(map, center, kernel)

[mh, mw] = size(map);
[kh, kw] = size(kernel);

mx1 = max(1, center(1) - kw / 2);
my1 = max(1, center(2) - N2);
mx2 = min(mw, center(1) + N2);
my2 = min(mh, center(2) + N2);

kx1 = max(1, center(1) - N2 - mx1);
ky1 = max(1, center(2) - N2 - my1);
kx2 = min(kw, mx2 - center(1) + N2 + 1);
ky2 = min(kh, my2 - center(2) + N2 + 1);

weights = map(my1:my2, mx1:mx2) .* kernel(ky1:ky2, kx1:kx2);
weights = weights(:) ./ sum(weights(:));

[x, y] = meshgrid((kx1:kx2) - N2, (ky1:ky2) - N2);

nx = mx + sum(x(:) .* weights) - 1;
ny = my + sum(y(:) .* weights) - 1;

shift = [nx, ny];