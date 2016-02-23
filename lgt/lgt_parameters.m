function parameters = improved_parameters()

parameters.size = 40;

parameters.modalities.enabled = 1;

parameters.modalities.mask = 20;
parameters.modalities.map_size = 150;

parameters.modalities.shape.enabled = 1;
parameters.modalities.shape.model = 'additive';
parameters.modalities.shape.expand = 15;
parameters.modalities.shape.persistence = 0.7;

parameters.modalities.motion.enabled = 1;
parameters.modalities.motion.lk_size = 8;
parameters.modalities.motion.persistence = 0.70;
parameters.modalities.motion.damping = 1;

parameters.modalities.color.enabled = 1;
parameters.modalities.color.regularize = 0;
parameters.modalities.color.prior = 0.1;
parameters.modalities.color.color_space = 'rgb';
parameters.modalities.color.bins = 16;
parameters.modalities.color.fg_persistence=0.95;
parameters.modalities.color.fg_sampling = 3;
parameters.modalities.color.bg_persistence = 0.5;
parameters.modalities.color.bg_spacing = 10;
parameters.modalities.color.bg_sampling = 35;

parameters.matching.global_move = 40;
parameters.matching.global_rotate = 0.1;
parameters.matching.global_scale = 0.01;
parameters.matching.global_samples_min = 50;
parameters.matching.global_samples_max = 300;
parameters.matching.global_elite = 10;
parameters.matching.local_radius = 10;
parameters.matching.local_samples = 40;
parameters.matching.local_elite = 5;
parameters.matching.iterations = 10;
parameters.matching.rigidity = 0.01;
parameters.matching.visual = 1;

parameters.matching.neighborhood_radius = 20;
parameters.matching.neighborhood = 'delaunay';

parameters.guide.enabled = 1;
parameters.guide.median = 0;
parameters.guide.distance = 3;
parameters.guide.similarity = 3;
parameters.guide.persistence = 0.5;

parameters.parts.type = 'hist16';
parameters.parts.part_size = 6;
parameters.parts.min = 10;
parameters.parts.max = 60;
parameters.parts.persistence = 0.8;
parameters.parts.merge = 3;
parameters.parts.remove = 0.1;

parameters.visualize.modalities_state = [];
