function parameters = ant_improved_parameters()

parameters.region_scale = 0.9;
parameters.size = 60; 
parameters.size_persistence = 0.9; % Size update ratio

parameters.motion.match = 10;
parameters.motion.guide = 10;
parameters.motion.parts = 1;
parameters.motion.blind = 0.1;

parameters.memory.type = 'kcf';
parameters.memory.kernel.type = 'gaussian';
parameters.memory.padding = 2;
parameters.memory.rescale = 1;
parameters.memory.capacity = 10;
parameters.memory.match = 0.85;
parameters.memory.guide = 0.5;
parameters.memory.overlap = 0.2;
parameters.memory.remove = 'lfu';
parameters.memory.quarantine = 10;
parameters.memory.size_factor = 1;
parameters.memory.size_influence = 10;
parameters.memory.candidates = 10;
parameters.memory.candidates_frequency = 7;
parameters.memory.candidates_reject = 20;
parameters.memory.candidates_overlap = 0.8;

parameters.global.mask = 8;
parameters.global.bins = 32;
parameters.global.fg_persistence = 0.9;
parameters.global.bg_persistence = 0.5;
parameters.global.neighborhood = 60;
parameters.global.purity = 0.9;
parameters.global.sufficiency = 0.5;
parameters.global.regularize = 2;
parameters.global.prior = 0.4;
parameters.global.region_scale = 1.2;

parameters.matching.iterations = 10; % Number of iterations of deformation
parameters.matching.neighborhood_radius = 12; % Neighborhood size
parameters.matching.flow.window = 7; % Optical flow window
parameters.matching.flow.levels = 3; % Optical flow pyramid layers
parameters.matching.flow.influence = 0.001; % Influence of flow-estimated parts
parameters.matching.flow.quality = 0.5;
parameters.matching.neighborhood = 'delaunay';
parameters.matching.sigma = 3;
parameters.matching.motion_prior = 0.001;

parameters.guide.size_expand = 5;
parameters.guide.persistence = 0.6;

parameters.parts.merge = 3;
parameters.parts.remove = 0.2;
parameters.parts.similarity = 3;
parameters.parts.part_size = 6;
parameters.parts.type = 'hist16';
parameters.parts.increase = 2;

% Visualization stuff, not important for the algorithm
parameters.visualize.template_state = [];
parameters.visualize.template_match = [];
parameters.visualize.candidates_state = [];
parameters.visualize.parts_adding = [];
parameters.visualize.segmentation_generation = [];
parameters.visualize.segmentation_threshold = [];
