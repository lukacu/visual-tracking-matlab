function [region, value] = match_kcf(image, region, model, parameters)

    position = region([2,1]) + region([4, 3]) / 2;

	%obtain a subwindow for detection at the position from last
	%frame, and convert to Fourier domain
	patch = get_subwindow(image, position, floor(model.scale * model.template_sz));

	patch = imresize(patch, model.template_sz, 'bilinear');
    
    features = get_features(patch, parameters, model.mask);
	zf = fft2(features);

	%calculate response of the classifier at all shifts
	switch parameters.kernel.type
	case 'gaussian',
		kzf = gaussian_correlation(zf, model.model_xf, parameters.kernel.sigma);
	case 'polynomial',
		kzf = polynomial_correlation(zf, model.model_xf, parameters.kernel.poly_a, parameters.kernel.poly_b);
	case 'linear',
		kzf = linear_correlation(zf, model.model_xf);
	end
	response = real(ifft2(model.model_alphaf .* kzf));  %equation for fast detection
    
    %target location is at the maximum response
    [row, col] = find(response == max(response(:)), 1);

    
    %subpixel accuracy?
    v_neighbors = response(mod(row + [-1, 0, 1] - 1, size(response,1)) + 1, col);
    h_neighbors = response(row, mod(col + [-1, 0, 1] - 1, size(response,2)) + 1);
    y = row + subpixel_peak(v_neighbors);
    x = col + subpixel_peak(h_neighbors);

    %take into account the fact that, if the target doesn't move,
    %the peak will appear at the top-left corner, not at the
    %center; the responses wrap around cyclically.
    if y > size(response,1) / 2,  %wrap around to negative half-space of vertical axis
        y = y - size(response,1);
        row = row - size(response,1);
    end
    if x > size(response,2) / 2,  %same for horizontal axis
        x = x - size(response,2);
        col = col - size(response,2);
    end

    
    position = position + model.scale * parameters.cell_size * [y - 1, x - 1];    
    
    siz = size(model.patch);
    region = [round(position([2, 1]) - siz([2, 1]) / 2), siz([2, 1])];

%     patch = patch_operation(zeros(region(4), region(3)), image, -region(1)-1, -region(2)-1, '=');
%     
%     i1 = (patch - mean2(patch)) ./ std2(patch);
%     i2 = model.normalized_patch;
%     er = exp(-(i1 - i2) .^ 2);
%     
%     a = gcf;
%     sfigure(11);
%     
%     imagesc(er);
%     sfigure(a);
    
    res = fftshift(response);
    res = res - min(res(:));
    value = max(res(:));
    
    
%     
    %matches = ((ordfilt2(res, 9 * 9, ...
    %    true(9))) == res) & res > max(res(:)) * 0.3;
    
    %sum(matches(:))
    
%     a = gcf;
%     sfigure(11);
    %response(matches) = 0;
%     imagesc(res);
%     sfigure(a);    
%     
    col = col - 1 + size(res, 2) / 2;
    row = row - 1 + size(res, 1) / 2;
    
	xs = floor(col) + (1:11) - floor(11/2);
	ys = floor(row) + (1:11) - floor(11/2);

    res(ys(ys >= 1 & ys < size(res, 1)), xs(xs >= 1 & xs < size(res, 2))) = 0;
    
    %patch = double(get_subwindow(image, region([2, 1]) + region([4, 3]) / 2, size(model.patch))) ./ 255;
    
    %sfigure(12); subplot(1, 2, 1); imagesc(patch); colormap gray;
    %subplot(1, 2, 2); imagesc(model.patch);
    
    %s1 = std(patch(:));
    %s2 = std(model.patch(:));
    %m1 = mean(patch(:));
    %m2 = mean(model.patch(:));    
    
    %ncc = sum( (patch(:) - m1) .* (model.patch(:) - m2) ./ (s1 * s2)) ./ numel(patch);    
    %value = ncc;
    psr = (value - mean(res)) / std(res);
    value = 1 - exp(-psr * 0.1073); % Similar response to NCC (0.8 is good)  

end

function delta = subpixel_peak(p)
	%parabola model (2nd order fit)
	delta = 0.5 * (p(3) - p(1)) / (2 * p(2) - p(3) - p(1));
	
	if ~isfinite(delta), delta = 0; end
end