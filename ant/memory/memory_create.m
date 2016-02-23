function [memory] = memory_create(parameters)

memory = struct('frequency', [], 'last', [], 'age', [], 'ids', [], 'parameters', parameters);
memory.instances = {};
memory.total = 0;

switch (memory.parameters.type)    
    case 'kcf'
        defaults.kernel.type = 'gaussian';
        defaults.kernel.sigma = 0.6;
        defaults.padding = 2; %1.5; % 1.2 ?
        defaults.lambda = 1e-4;  %regularization
        defaults.output_sigma_factor = 0.1;  %spatial bandwidth (proportional to target)
        defaults.interp_factor = 0.075;
        defaults.kernel.poly_a = 1;
        defaults.kernel.poly_b = 9;
        defaults.gray = false;
        defaults.gradient = false;
        defaults.hog = true;
        defaults.hog_orientations = 9;
        defaults.cell_size = 4;
        memory.parameters = struct_merge(memory.parameters, defaults);

end
