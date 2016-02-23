function [resized] = image_resize(image, scale)

resized = image_create(imresize(image_convert(image, 'rgb'), scale));

