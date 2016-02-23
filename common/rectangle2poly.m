function [px, py] = rectangle2poly(x, y, w, h, r)

A = [cos(r) * w, -sin(r) * h, x; sin(r) * w, cos(r) * h, y; 0, 0, 1];

p = A * [-0.5, -0.5, 1; -0.5, 0.5, 1; 0.5, 0.5, 1; 0.5, -0.5, 1]';

px = p(1, :);
py = p(2, :);
