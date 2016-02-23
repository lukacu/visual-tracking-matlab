function [template_region, template_value] = memory_match(template, image, search_region, fh)

if nargin < 4
    
    fh = [];
    
end;

template_region = nan(length(template.instances), 4);
template_value = nan(length(template.instances), 1);

if ~isempty(fh)
    sfigure(fh);
    imshow(image);
    hold on;
    [x, y] = rect2points(search_region);
    plotc(x, y, 'Color', c('black'));
end;

for i = 1:length(template.instances)

    switch template.parameters.type
        
        case 'ncc'
            [rmax, smax] = match_ncc(image, search_region, template.instances{i});
            
        case 'kcf'
            
            [rmax, smax] = match_kcf(image, search_region, template.instances{i}, template.parameters);
    end
                

    if ~isempty(fh)
        [x, y] = rect2points(rmax);
        plotc(x, y, 'Color', c('violet'));
        text(x(1), y(1) + 5, sprintf('%.4f', smax), 'Color', c('violet'));
    end;
    
    template_value(i) = smax;
    template_region(i, :) = rmax;

    
end;

% if ~isempty(fh)
%     if ~isempty(overlap_region)
%         [x, y] = rect2points(overlap_region);
%         plotc(x, y, 'Color', c('red'));
%         text(x(1), y(1) + 5, sprintf('%.4f', overlap_score), 'Color', c('red'));
%     end;
% 
% 
%     if ~isempty(score_region)
%         [x, y] = rect2points(score_region);
%         plotc(x, y, 'Color', c('green'));
%         text(x(1), y(1) + 5, sprintf('%.4f', score_max), 'Color', c('green'));
%     end;
% end;
if ~isempty(fh)
    hold off;
end
