function plot_color_cloud(H, colorspace)

if nargin < 2
    colorspace = 'rgb';
end

[rbins, gbins, bbins] = size(H);

mask = H(:) > eps * 10;

S = (H(mask) ./ max(H(:))) * 200;

[X, Y, Z] = meshgrid(1:rbins, 1:gbins, 1:bbins);

switch colorspace
    case 'rgb'
    C = [double(Y(mask)) / rbins, double(X(mask)) / gbins, double(Z(mask)) / bbins];
    case 'bgr'
    C = [double(Z(mask)) / rbins, double(X(mask)) / gbins, double(Y(mask)) / bbins];
    case 'hsv'
    C1 = [double(Y(mask)) / rbins, double(X(mask)) / gbins, double(Z(mask)) / bbins];
    C = squeeze(hsv2rgb(reshape(C1, [1, size(C1)])));
end
scatter3(X(mask), Y(mask), Z(mask), S, C, 'o');



