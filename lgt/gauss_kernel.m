function [K] = gauss_kernel(Sigma)

w = max(1, 1 + 6 * round(sqrt(Sigma(1, 1))));
h = max(1, 1 + 6 * round(sqrt(Sigma(2, 2))));

mean = [w h] / 2;

[X, Y] = meshgrid(1:w, 1:h);

K = gauss(mean, Sigma, [X(:), Y(:)]);

K = reshape(K, h, w);

% K = zeros(w, h);
% 
%     for i = 1:w
%         for j = 1:h
%             K(i, j) = ([i j] - mean) * Sigma * ([i j] - mean)';
%         end;
%     end;
%     
% K = exp(-0.5 * K);

