function image = image_create(input)

if isstruct(input)
	image = input;
	return;
end

if ischar(input)
    input = imread(input);
end;

if size(input, 3) > 1
    image.rgb = input;
else
    image.gray = input;
end;

image.offset = [0, 0];