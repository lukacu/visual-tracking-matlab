% Calculates 2D weighted geometrical transform
%
% Input parameters: P1 - first set of points (nx2)
%                   P2 - second set of points (nx2)
%
% Output: T - 3x3 transformation matrix
%
function [T] = wtransform(P1, P2, weights, type)

% take the minimum amount of available points
p = min([size(P1, 1), size(P2, 1)]);

if nargin < 3
    weights = ones(p, 1);
end

if nargin < 4
    if p >= 3
        type = 'affine';
    elseif p == 2
        type = 'similarity';
    elseif p == 1
        type = 'translate';
    else
        T = eye(3);
        return;
    end;
end

switch type
    case 'affine'
		A = zeros(2*p, 6);
		b = zeros(2*p, 1);

		for i = 1:p
			A(i*2-1, :) = [P1(i, 1), P1(i, 2), 0, 0, 1, 0];
			A(i*2, :) = [0, 0, P1(i, 1), P1(i, 2), 0, 1];
			b(i*2-1) = P2(i, 1);
			b(i*2) = P2(i, 2);
		end;
		weights = repmat(weights(:), 1, 2);
		% solve system
		x = lscov(A,b, weights(:));

		% build the transformation matrix
		T = [x(1) x(2) x(5); x(3) x(4) x(6); 0 0 1];
        return;
    case 'similarity'

        A = zeros(2*p, 4);
        b = zeros(2*p, 1);

        for i = 1:p
            A(i*2-1, :) = [P1(i, 1), -P1(i, 2), 1, 0];
            A(i*2, :) = [P1(i, 2), P1(i, 1), 0, 1];
            b(i*2-1) = P2(i, 1);
            b(i*2) = P2(i, 2);
        end;
        we = repmat(weights(:), 1, 2);

        % solve system
        x = lscov(A,b, we(:));

        % build the transformation matrix
        T = [x(1), -x(2), x(3); x(2), x(1), x(4); 0 0 1];
        return;
    case 'transform'
        t = wmean(P2 - P1, weights);

        % build the transformation matrix
        T = [1, 0, t(1); 0, 1, t(2); 0 0 1];
        return;
end;

T = eye(3);


