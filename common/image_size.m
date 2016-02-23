function [height, width] = image_size(image)

if isfield(image, 'rgb')
	width = size(image.rgb, 2);
	height = size(image.rgb, 1);
else
	width = size(image.gray, 2);
	height = size(image.gray, 1);
end

if nargout == 1
	height = [height, width];
end

