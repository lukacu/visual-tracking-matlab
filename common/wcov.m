function [result] = wcov(values, weights)

if size(values, 1) ~= numel(weights)
	error('Dimension mismatch');
end;

weights = weights(:);
weights = weights ./ sum(weights);

if (any(weights == 1))
    result = 0;
    return;
end;

sizes = size(values);
sizes(1) = 1;

xc = bsxfun(@minus, values, wmean(values, weights, 1));  % Remove mean

result = (xc' * (xc .* repmat(weights, sizes))) ./ (1 - sum(weights .^ 2));


