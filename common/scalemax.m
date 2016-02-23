function [M] = scalemax(N, a)

t = max(N);
for i = ndims(N)-1
    t = max(t);
end;

M = ((N) ./ (t / a));