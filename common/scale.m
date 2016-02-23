function [M] = scale(N, a)

t = max(N);
b = min(N);
for i = ndims(N)-1
    t = max(t);
    b = min(b);
end;

M = ((N - b) ./ (t - b)) .* a;