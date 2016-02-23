function [cut_region, threshold, quality] = segmentation_get_threshold(map, region, purity, sufficency, fh)

    if nargin < 4
       fh = []; 
    end

    cut_region = patch_operation(zeros(region(4), region(3)), map, -region(1), -region(2), '=');

    all = sum(map(:));
    positive = sum(cut_region(:));
    
    N = 100;
    bins = linspace(0, 1, N);
    hist_positive = fliplr(histc(cut_region(:), bins)');
    hist_all = fliplr(histc(map(:), bins)');
    
    contained = cumsum(hist_positive) ./ cumsum(hist_all);
        
    i = find(contained > purity, 1, 'last');
    threshold = bins(N - i + 1);
    
%     if ~isempty(threshold)
%         threshold = max(threshold, 0.6);
%     end;
    
    if isempty(threshold)
        threshold = 1;
    end;

    hist_positive = hist_positive ./ numel(cut_region);
    i = find(cumsum(hist_positive) > sufficency, 1, 'first');
    threshold2 = bins(N - i + 1);

    threshold = max(threshold2, threshold);

    if ~isempty(fh);
        sfigure(fh); %, 'Name','Segmentation threshold','NumberTitle','off');
        
        subplot(2, 2, 1);
        bar(contained);

        subplot(2, 2, 2);
        bar(cumsum(hist_positive)); title('Positive');
        
        subplot(2, 2, 3); title('Map');
        imagesc(map);
        
        subplot(2, 2, 4);
        imagesc(map > threshold); title(sprintf('threshold = %.3f', threshold));

%         subplot(3, 1, 3);
%         imagesc(map > threshold2); title(sprintf('threshold = %.3f', threshold2));    
    end;    
    

    quality = positive / all;

    