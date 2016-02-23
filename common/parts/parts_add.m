function [parts, indices, valid] = parts_add(parts, image, positions, sizes)

    n = min([size(positions, 1), size(sizes, 1)]);
    sizes = sizes(1:n, :);
    positions = positions(1:n, :);
    
    regions = int32([positions(1:n, :) - sizes(1:n, :) / 2, sizes(1:n, :)]);
    gray = image_convert(image, 'gray');
    models = partassemble(gray, regions, parts.bins);
    
    % If a patch is initialized outside a valid area it gets an empty model
    % we have to eliminate those patches
    valid = ~cellfun(@isempty, models, 'UniformOutput', true);
    n = sum(valid);
   
    indices = (1:n) + numel(parts.properties);
    
    parts.positions = cat(1, parts.positions, positions(valid, :));
    parts.sizes = cat(1, parts.sizes, sizes(valid, :));
    parts.importance = cat(1, parts.importance, zeros(n, 1));
    parts.group = cat(1, parts.group, zeros(n, 1));

    ids = num2cell(parts.counter + (1:n));
    [parts.properties(end+1:end+n, 1).ids] = deal(ids{:});
    
    parts.trajectories(end+1:end+n, 1) = num2cell(positions(valid, :), 2);
    
    parts.text(end+1:end+n, 1) = cell(n, 1);

    parts.data = cat(1, parts.data, models(valid));
    
    parts.counter = parts.counter + n;    

end
