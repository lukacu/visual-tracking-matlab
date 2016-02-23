function [model] = create_kcf(image, position, mask, parameters)

template_size = 100;
target_sz = size(mask);
pos = position([2, 1]);

template_sz = floor(target_sz + parameters.padding * sqrt(prod(target_sz)));

real_patch = get_subwindow(image, pos, target_sz);

if template_sz(1) > template_sz(2),  %height is longer
     scale = template_sz(1) / template_size;
else
     scale = template_sz(2) / template_size;
end
template_sz = floor(template_sz / scale);
%target_sz = target_sz / scale;

output_sigma = sqrt(prod(template_sz / (1 + parameters.padding))) * parameters.output_sigma_factor / parameters.cell_size;
yf = fft2(gaussian_shaped_labels(output_sigma, floor(template_sz / parameters.cell_size)));

%store pre-computed cosine window
cosine_mask = hann(size(yf,1)) * hann(size(yf,2))';

%obtain a subwindow for training at newly estimated target position
patch = get_subwindow(image, pos, floor(scale * template_sz));
patch = imresize(patch, template_sz, 'bilinear');

if parameters.hog

    mask2 = padarray(mask, floor((scale * template_sz - target_sz) / 2));
    %H = fspecial('gaussian', [41, 41], 5);
    %mask2 = imfilter(mask2, H, 'replicate');
    mask = imresize(mask2, size(cosine_mask), 'bilinear') .* cosine_mask;

else
   mask = cosine_mask;
    
end

%sfigure(12); imagesc(mask);
%mask = cosine_mask;

ftrs = get_features(patch, parameters, mask);
xf = fft2(ftrs);

%Kernel Ridge Regression, calculate alphas (in Fourier domain)
switch parameters.kernel.type
case 'gaussian',
    kf = gaussian_correlation(xf, xf, parameters.kernel.sigma);
case 'polynomial',
    kf = polynomial_correlation(xf, xf, parameters.kernel.poly_a, parameters.kernel.poly_b);
case 'linear',
    kf = linear_correlation(xf, xf);
end

model.model_num = yf .* kf;
model.model_den = kf .* (kf + parameters.lambda);
model.model_xf = xf;
model.model_alphaf = model.model_num ./ model.model_den;
model.patch = double(real_patch) / 255;
model.normalized_patch = (double(real_patch) - mean2(real_patch)) ./ std2(real_patch);
model.yf = yf;

model.mask = cosine_mask;
model.template_sz = template_sz;
model.scale = scale;
