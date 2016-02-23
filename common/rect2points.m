function [points, y] = rect2points(rectangle)

    points = [rectangle(1:2); rectangle(1), rectangle(2) + rectangle(4); ...
        rectangle(1:2) + rectangle(3:4); rectangle(1) + rectangle(3), rectangle(2)];

    if nargout > 1
       y = points(:, 2); 
       points = points(:, 1);
    end