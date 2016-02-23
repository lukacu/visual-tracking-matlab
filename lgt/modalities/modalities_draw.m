function modalities_draw(modalities, handle)

sfigure(handle);

%title('LGT Global modalities');

if modalities.color.parameters.enabled && ~isempty(modalities.color.map)
    subplot(2, 2, 1); 
    imagesc(modalities.color.map); title('Color');
end;

if modalities.motion.parameters.enabled && ~isempty(modalities.motion.map)
    subplot(2, 2, 2); 
    imagesc(modalities.motion.map); title('Motion');
end;

if modalities.shape.parameters.enabled && ~isempty(modalities.shape.map)
    subplot(2, 2, 3); 
    imagesc(modalities.shape.map); title('Shape');
end;

if  ~isempty(modalities.map)
    subplot(2, 2, 4); title('Combined');
    imagesc(modalities.map);
end;

colormap gray;