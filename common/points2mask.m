function [mask] = points2mask(x, y, m, n)
    
    mask = false(m, n);

    x = round(x);
    y = round(y);
    
    valid = x >= 0 & y >= 0 & x < n & y < m;

	mask(sub2ind(size(mask), y(valid) + 1, x(valid) + 1)) = true;
