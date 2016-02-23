function [regions, values] = match_kcfs(image, region, model, parameters)

    position = region([2,1]) + region([3, 4]) / 2;

	%obtain a subwindow for detection at the position from last
	%frame, and convert to Fourier domain
	patch = get_subwindow(image, position, floor(model.scale * model.template_sz));

	patch = imresize(patch, model.template_sz, 'bilinear');
    
	zf = fft2(get_features(patch, parameters, model.cos_window));

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
    region = [position([2, 1]) - siz([2, 1]) / 2, siz([2, 1])];
    
    res = fftshift(response);
    res = res - min(res(:));
    value = max(res(:));
    
    col = col - 1 + size(res, 2) / 2;
    row = row - 1 + size(res, 1) / 2;
    
	xs = floor(col) + (1:11) - floor(11/2);
	ys = floor(row) + (1:11) - floor(11/2);

    res(ys(ys >= 1 & ys < size(res, 1)), xs(xs >= 1 & xs < size(res, 2))) = 0;
    
    psr = (value - mean(res)) / std(res);
    
    value = 1 - exp(-psr * 0.1073);
%      N = get_subwindow(res, [row, col] - 1 + size(res) / 2, [11, 11]);
%     N(6, 6) = 0;
%     
%     
    
end

function delta = subpixel_peak(p)
	%parabola model (2nd order fit)
	delta = 0.5 * (p(3) - p(1)) / (2 * p(2) - p(3) - p(1));
	
	if ~isfinite(delta), delta = 0; end
end