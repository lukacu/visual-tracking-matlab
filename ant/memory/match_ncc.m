function [region, value] = match_ncc(image, search_region, model)

    [height, width] = size(image);

    window = 0;
    [theight, twidth] = size(model.patch);

    x1 = max(0, round(search_region(1) - (window + twidth) / 2));
    y1 = max(0, round(search_region(2) - (window + theight) / 2));
    x2 = min(width-1, round(search_region(1) + search_region(3) + (window + twidth) / 2));
    y2 = min(height-1, round(search_region(2) + search_region(4) + (window + theight) / 2));

    cut = image((y1:y2)+1, (x1:x2)+1);
    
    if any(size(cut) < size(model.patch))
        value = 0;
        region = [0, 0, 1, 1];
        return;
    end;

    C = normxcorr2(model.patch, cut);

    pad = size(model.patch) - 1;
    center = size(cut) - pad - 1;
    C = C([false(1,pad(1)) true(1,center(1))], [false(1,pad(2)) true(1,center(2))]);

    x1 = x1 + pad(2);
    y1 = y1 + pad(1);
    [smax, imax] = max(C(:));
    
    if isempty(smax)
        value = 0;
        region = [0, 0, 1, 1];
        return;
    end;
    
    [my, mx] = ind2sub(size(C), imax(1));
    
    region = [x1 + mx - twidth, y1 + my - theight, twidth, theight];
    value = smax;