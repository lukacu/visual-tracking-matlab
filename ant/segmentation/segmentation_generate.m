function [probability] = segmentation_generate(segmentation, image, fh)
    
    if nargin < 3
       fh = []; 
    end

	if ~isempty(segmentation.foreground)

        bins = segmentation.parameters.bins;    
        imagecs = double(image_convert(image, 'rgb'));
        edges = {linspace(0,256,bins+1), linspace(0,256,bins+1), linspace(0,256,bins+1)};

        foreground_map = cv.calcBackProject(imagecs, segmentation.foreground, edges);
        background_map = cv.calcBackProject(imagecs, segmentation.background, edges);

        sum_map = foreground_map + background_map + eps ;
        foreground_map = foreground_map./sum_map ;
        background_map = background_map./sum_map ;

        if ~isempty(fh)
            sfigure(fh);
            subplot(1, 3, 1);
            imagesc(foreground_map);   
            subplot(1, 3, 2);
            imagesc(background_map);
            colormap jet;
        end;
        
		regularize = segmentation.parameters.regularize;
        H = fspecial('gaussian', [15, 15], regularize);
        foreground_map = imfilter(foreground_map, H, 'replicate');
        background_map = imfilter(background_map, H, 'replicate');
        
        p = segmentation.parameters.prior; 
        probability = p .* (foreground_map) ./ ((p .* foreground_map + (1 - p) .* background_map));
        

        if ~isempty(fh) 
            subplot(1, 3, 3);
            imagesc(probability);
        end;
        
    else
		probability = [];
     
	end;

end

    