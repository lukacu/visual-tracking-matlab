function rectangle = points2rect(points)

	if (min(size(points)) == 1)

		x = points(1:2:end);
		y = points(2:2:end);

	else

		x = points(1, :);
		y = points(2, :);

	end;

	x1 = min(x);
	y1 = min(y);
	x2 = max(x);
	y2 = max(y);

    rectangle = [x1, y1, x2 - x1, y2 - y1];

