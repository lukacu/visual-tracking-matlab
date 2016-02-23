function  [raw, image] = image_convert(image, type)

if isfield(image, type)
	raw = image.(type);
	return;
end;

switch (type)
	case 'gray'
		if isfield(image, 'rgb')
		    image.gray = rgb2gray(image.rgb);
		end;
		raw = image.gray;
	case 'rgb'
		if isfield(image, 'gray')
            image.rgb = cat(3, image.gray, image.gray, image.gray);
		end;
		raw = image.rgb;
	case 'hsv'
		if isfield(image, 'rgb')
            image.hsv = rgb2hsv(image.rgb);
		end;
		raw = image.hsv;
	case 'ycbcr'
		if isfield(image, 'rgb')
            image.ycbcr = rgb2ycbcr(image.rgb);
		end;
		raw = image.ycbcr;
	case 'gxy'
		[gray, image] = image_convert(image, 'gray');        
        [gx, gy] = gaussderiv(double(gray) ./ 255, 1);        
        image.gxy = cat(3, gray, gx .* 255, gy .* 255);
		raw = image.gxy;
	case 'g12'
		[gray, image] = image_convert(image, 'gray');
        H1 = fspecial('gaussian', [11, 11], 3);
        H2 = fspecial('gaussian', [21, 21], 5);        
        g1 = imfilter(gray, H1, 'replicate');        
        g2 = imfilter(gray, H2, 'replicate');             
        image.g12 = cat(3, gray, g1, g2);
		raw = image.g12;         
    otherwise
        error('Unknown color space');
end


