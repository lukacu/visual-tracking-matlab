function [memory] = memory_update(memory, operation, varargin)

new_instances = [];

switch operation
    case 'update'
        %image = varargin{1};
        id = varargin{2};
        %position = varargin{3};
        %mask = varargin{4};
    
        memory.frequency(id) = memory.frequency(id) + 1;
        memory.last(id) = 0;

%         switch template.parameters.type
% 
%             case 'ncc'
%                 x1 = max(0, region(1));
%                 y1 = max(0, region(2));
%                 x2 = min(size(image, 2)-1, region(1) + region(3) - 1);
%                 y2 = min(size(image, 1)-1, region(2) + region(4) - 1);
% 
%                 patch = image((y1:y2)+1, (x1:x2)+1);
% 
%                 factor = 0.5;
%                 
%                 template.instances{id} = factor * template.instances{id} + (1 - factor) * patch;
% 
%             case 'kcf'
% 
% 
%                 template.instances{id} = update_kcf(image, region, template.instances{id}, template.parameters);
%                 
%         end            
        
    case 'add'
        
        image = varargin{1};
        position = round(varargin{2});
        mask = varargin{3}; 
        
        if nargin > 5
            proposed_region = varargin{4};
        else
        	proposed_region = round(rectangle_operation('setcenter', ...
                    [0, 0, size(mask, 2), size(mask, 1)], position));
        end

        switch memory.parameters.type

            case 'ncc'

                region = round(rectangle_operation('setcenter', ...
                    [0, 0, size(mask, 2), size(mask, 1)], position));

                x1 = max(0, region(1));
                y1 = max(0, region(2));
                x2 = min(size(image, 2)-1, region(1) + region(3) - 1);
                y2 = min(size(image, 1)-1, region(2) + region(4) - 1);

                patch = image((y1:y2)+1, (x1:x2)+1);

                new_instances = struct('patch', patch, 'mask', mask);

            case 'kcf'

                new_instances = create_kcf(image, position, mask, memory.parameters);
        end
        
        new_instances.region = proposed_region;
        
    case 'insert'
        new_instances = varargin{1};
    
    case 'age'
        
        memory.age = memory.age + 1;
        memory.last = memory.last + 1;

end

if ~isempty(new_instances)
    
    if ~iscell(new_instances)
        new_instances = {new_instances};
    end;
    
    for k = 1:numel(new_instances)
    
        if numel(memory.instances) >= memory.parameters.capacity

            switch memory.parameters.remove

                case 'lru'

    %         candidates = find(template.frequency == min(template.frequency));
    %         [v, i] = max(template.last(candidates));        
    %         mask(candidates(i)) = false;

                case 'lfu'
                    [~, i] = min(memory.frequency ./ max(memory.age));
                    
                case 'fifo'
                    [~, i] = max(memory.age);
            end;

            memory = memory_remove(memory, i);
        end

        memory.instances{end + 1} = new_instances{k};
        memory.frequency(end + 1) = 0;
        memory.last(end + 1) = 0;
        memory.age(end + 1) = 1; 
        memory.ids(end + 1) = memory.total + 1; 
        memory.total = memory.total + 1;
    end;
    
end

