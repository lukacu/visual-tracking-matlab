function x = get_features(im, features, mask)
%GET_FEATURES
%   Extracts dense features from image.
%
%   X = GET_FEATURES(IM, FEATURES)
%   Extracts features specified in struct FEATURES, from image IM. The
%   features should be densely sampled, in cells or intervals of
%   FEATURES.CELL_SIZE.
%   The output has size [height in cells, width in cells, features].
%
%   To specify HOG features, set field 'hog' to true, and
%   'hog_orientations' to the number of bins.
%
%   To experiment with other features simply add them to this function
%   and include any needed parameters in the FEATURES struct. To allow
%   combinations of features, stack them with x = cat(3, x, new_feat).
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/
    
	if features.hog,
		%HOG features, from Piotr's Toolbox
		x = double(fhog(single(im) / 255, features.cell_size, features.hog_orientations));
		x(:,:,end) = [];  %remove all-zeros channel ("truncation feature")
	end
	
	if features.gray,
		%gray-level (scalar feature)
		x = double(im) / 255;
		
		x = x - mean(x(:));
        
        if features.cell_size > 1
        
            x = imresize(x, floor(size(x) / features.cell_size), 'bilinear');
            
        end
	end
    
    if features.gradient,
        % gradient features - similar to hog, but simplier
        g = double(im) / 255;
        
        if size(im, 3) > 1
            im = rgb2gray(im);
        end
        gradients = getGradImages(double(im), features.gradient_sigma);
        x = double(gradients);
        
        %g = double(im) / 255;
        %x(:,:,3) = g - mean(g(:));
        
		x(:,:,3:5) = g - mean(g(:));
        
    end
    
    %tfh = gcf;
    %figure(1); clf; colormap gray;
    %imagesc(sum(x, 3));
    %set(0, 'CurrentFigure', tfh);
    
	%process with mask if needed
	if ~isempty(mask),
        x = bsxfun(@times, x, mask);
	end
	
end
