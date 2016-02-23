function [result] = wmean(values, weights, dimension)

if nargin < 3
	dimension = 1;
end

if size(values, dimension) ~= numel(weights) || dimension > ndims(values)
	error('Dimension mismatch');
end;

weights = weights(:);
sizes = size(values);
sizes(dimension) = 1;

result = sum(values .* repmat(shiftdim(weights, dimension-1), sizes), dimension) ./ sum(weights);
