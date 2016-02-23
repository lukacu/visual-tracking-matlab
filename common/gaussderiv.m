function [Dx, Dy, varargout] = gaussderiv(img, sigma)

x = floor(-3.0*sigma+0.5):floor(3.0*sigma+0.5);
G = exp(-x.^2/(2*sigma^2));
G = G/sum(sum(G));

D = -2 * (x .* exp(-x .^ 2 / (2 * sigma ^ 2))) / (sqrt(2 * pi) * sigma ^ 3);
D = D / (sum(abs(D))/2) ;

Dx = conv2(conv2(img,D,'same') ,G','same');
Dy = conv2(conv2(img,G,'same') ,D','same');

if nargout > 2
varargout{1} = conv2(conv2(Dx, D, 'same'), G', 'same');
end

if nargout > 3
varargout{2} = conv2(conv2(Dx, G, 'same'), D', 'same');
end

if nargout > 4
varargout{3} = conv2(conv2(Dy, G, 'same'), D', 'same');
end

