function [positions, values] = segmentation_sample(image, mask, probability, N, fh)
    
    if nargin < 5
       fh = []; 
    end

%     threshold2 = mean(probability(:));
% 
%     threshold = median(probability(:)); % < tole mogoče ni pametno !!!
% 
%     threshold = max(threshold, threshold2);
%     threshold
%     segmentation_mask = probability > threshold;
% 
% 
%     if isempty(mask)
%         mask = segmentation_mask;
%     else
% 
% 
%         mask = mask .* segmentation_mask;
%     end

    mask = imerode(mask, ones(5));
    
	gray = image_convert(image, 'gray');
 min(gray(:));
 %max(gray(:)) 
    corners = cv.cornerHarris(gray);
% min(corners(:))
% max(corners(:))
    [x, y] = meshgrid(1:size(gray,2), 1:size(gray, 1));    
    corners = corners + (1 + sin(x) + sin(y)) * 0.0001;
    
    corners(~mask) = 0;
    
    parts = ((ordfilt2(corners, 9 * 9, ...
        true(9))) == corners) & corners > eps;

%     parts = parts | ((ordfilt2(mapsmooth, 9 * 9, ...
%         true(9))) == mapsmooth);
    
    [y, x] = find(parts .* mask);

	ind = sub2ind(image_size(image), y, x);

 	[values, indices] = sort(probability(ind), 'descend');
    

    % values ?? what to do with low values?
    % We are testing removing them.
%     remove = values < 0.8;
%     indices = indices(~remove);
%     values = values(~remove);

    if ~isempty(fh)
        sfigure(fh);
        subplot(2, 2, 1);
        imagesc(gray);
        colormap gray;
        subplot(2, 2, 2);
        imagesc(corners);
        subplot(2, 2, 3);
        imagesc(mask);    
        subplot(2, 2, 4);
        imagesc(parts);   
    end;
    
    if numel(indices) < N
        %positions = [x, y];
        positions = [x(indices), y(indices)];
    else
        positions = [x(indices(1:N)), y(indices(1:N))];
        values = values(1:N);
    end

    if ~isempty(positions)
        positions = bsxfun(@plus, positions, image.offset);
    end;
    
end


