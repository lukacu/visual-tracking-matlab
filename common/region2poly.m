function [x, y] = region2poly(region)

	if size(region, 1) == 2 && size(region, 1) > 2
		x = region(:, 1);
		y = region(:, 2);
		return;
	end


	if numel(region) == 4
		[x, y] = rect2points(region(:)');
	elseif numel(region) == 5
		[x, y] = rectangle2poly(region(1), region(2), region(3), region(4), region(5));
    else
		region = region(:);
		x = region(1:2:end);
		y = region(2:2:end);
	end


