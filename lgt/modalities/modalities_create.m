function [modalities] = modalities_create(parameters)

    modalities.map_size = parameters.map_size;
    
    modalities.pastimage = [];
    modalities.map = [];
    modalities.sample_mask = [];
    modalities.pastposition = [];
    
    modalities.color = struct('parameters', parameters.color, 'map', [], 'foreground', [], 'background', []);
    
    if isstruct(modalities.color.parameters.bins)
        modalities.color.parameters.bins = [modalities.color.parameters.bins.a, modalities.color.parameters.bins.b, modalities.color.parameters.bins.c];
    else
        modalities.color.parameters.bins = [modalities.color.parameters.bins, modalities.color.parameters.bins, modalities.color.parameters.bins];
    end    
    
    modalities.color.foreground = normalize(ones(modalities.color.parameters.bins));
    modalities.color.background = normalize(ones(modalities.color.parameters.bins));
    
    modalities.motion = struct('parameters', parameters.motion, 'map', [], 'past', []);
    
    modalities.shape = struct('parameters', parameters.shape, 'map', [], 'shape', []);
