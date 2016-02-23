function [memory, instances] = memory_remove(memory, index)

    if isempty(index)
        instances = {};
        return;
    end;

    mask = true(numel(memory.instances), 1);

    instances = memory.instances(index);
    
    mask(index) = false;
    memory.instances = memory.instances(mask); 
    memory.frequency = memory.frequency(mask);
    memory.last = memory.last(mask);
    memory.age = memory.age(mask);
    memory.ids = memory.ids(mask);

