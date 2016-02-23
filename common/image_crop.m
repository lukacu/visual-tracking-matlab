function [cropped] = image_crop(image, region)

    [x, y, w, h] = rectangle_operation('deal', round(region));

    [height, width] = image_size(image);
    
	xs = x + (1:w);
	ys = y + (1:h);
	
	%check for out-of-bounds coordinates, and set them to the values at
	%the borders
	xs(xs < 1) = 1;
	ys(ys < 1) = 1;
	xs(xs > width) = width;
	ys(ys > height) = height;    
    
    rgb = image_convert(image, 'rgb');
        
    cropped = image_create(rgb(ys, xs, :));
        
    cropped.offset = [x, y];