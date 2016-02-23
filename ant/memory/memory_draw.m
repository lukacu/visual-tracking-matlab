function memory_draw(template, handle)

sfigure(handle); clf;

for i = 1:numel(template.instances)
    %subplot(1, template.parameters.capacity, i); 
    subplot(1, numel(template.instances), i); 
    switch template.parameters.type
        case 'ncc'
            [h, w] = size(template.instances{i}.patch);
            imshow(template.instances{i}.patch);
        case 'kcf'
            [h, w] = size(template.instances{i}.patch);
            imshow(template.instances{i}.patch);    
    end;
    
%     if template.last(i) == 0
%     hold on;
%         [x, y] = rect2points([1, 1, w, h]);
%         plotc(x, y, 'Color', [1, 0, 0], 'LineWidth', 3);
%     hold off;
%     end;
    %title(sprintf('%dx%d %d, %d, %d', w, h, template.age(i), template.frequency(i), template.last(i)));
    
    title({sprintf('Age: %d', template.age(i)), ...
        sprintf('Used: %d %%',round(100 * template.frequency(i) / template.age(i)))});
end;

