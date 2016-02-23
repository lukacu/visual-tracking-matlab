function [positions] = modalities_sample(modalities, mask, N, kernel)
    
    if isempty(modalities.map)
        positions = [];
        return;
    end

    modalities.map = scalemax(modalities.map, 1);
    
    mask = mask .* (imfilter(double(modalities.map > 0.2), ones(5)) > 15);
    
    positions = zeros(N, 2);
    
    for i = 1:N

        map = modalities.map .* mask;

        map(map < 0.2) = 0;
                
        position = sample_probability_map(map');
        
        if (isempty(position) || any(position < 1) || any(position > modalities.map_size))
            
            if (i == 1)
                positions = [];
            else
                positions = positions(1:i-1, :);
            end;
            
            break;
        end;
        
        x = position(1);
        y = position(2);  

        positions(i, 1:2) = [x y];

        mask = mask .* (1 - conv2(double(points2mask(x, y, modalities.map_size, modalities.map_size)), kernel, 'same'));
        
    end;

    if ~isempty(positions)
% 
%         figure(3); imagesc(modalities.map);
%         hold on; plot(positions(:, 1), positions(:, 2), 'r+');
% 
%         figure(4); imagesc(mask); 
%         
        positions = positions - modalities.map_size / 2;
        
    end;