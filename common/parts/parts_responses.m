function responses = parts_responses(parts, indices, positions, image)

if isempty(indices)
	indices = true(length(parts.properties), 1);
end

sizes = repmat(shiftdim(parts.sizes(indices, :)', -1), [size(positions, 1), 1, 1]);

responses = partcompare(image_convert(image, 'gray'), parts.data(indices), int32(cat(2, positions - sizes / 2, sizes)), parts.bins);


