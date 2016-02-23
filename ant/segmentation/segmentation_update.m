function [segmentation] = segmentation_update(segmentation, image, region, type)

    if nargin < 4
        type = 'both';
    end;

    bins = segmentation.parameters.bins;    
    imagecs = image_convert(image, 'rgb');
    edges = {linspace(0,256,bins+1), linspace(0,256,bins+1), linspace(0,256,bins+1)}; 
    
    [height, width] = image_size(image);
    
    if islogical(region) 
        fgmask = region;
    else
        [x, y] = region2poly(region);
        fgmask = poly2mask(x, y, height, width);
    end
    
    if strcmpi(type, 'both') || strcmpi(type, 'foreground')

        fgappearance = normalize(cv.calcHist(imagecs, edges, 'Mask', fgmask));

        if isempty(segmentation.foreground)
            segmentation.foreground = fgappearance;
        else
            segmentation.foreground = segmentation.parameters.fg_persistence * segmentation.foreground + (1 - segmentation.parameters.fg_persistence) * fgappearance;
        end;
      
    end;
    
    if strcmpi(type, 'both') || strcmpi(type, 'background')
    
        spacing = segmentation.parameters.neighborhood;

        bgmask = imdilate(fgmask, ones(spacing)) & ~fgmask;

        bgappearance = normalize(cv.calcHist(imagecs, edges, 'Mask', bgmask)) + 100 * eps;

        if isempty(segmentation.background)
            segmentation.background = bgappearance;
        else    
            segmentation.background = segmentation.parameters.bg_persistence * (segmentation.background) + (1 - segmentation.parameters.bg_persistence) * bgappearance;
        end;

    end;
    
    p = 0.1; 
    segmentation.model = p .* (segmentation.foreground) ./ ((p .* segmentation.foreground + (1 - p) .* segmentation.background));

end

