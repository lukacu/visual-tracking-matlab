function [state, location, values] = tracker_l1apg_initialize(image, region, varargin)

% parameters setting for tracking
defaults.lambda = [0.2,0.001,10]; % lambda 1, lambda 2 for a_T and a_I respectively, lambda 3 for the L2 norm parameter
% set para.lambda = [a,a,0]; then this the old model
defaults.angle_threshold = 40;
defaults.Lip	= 8;
defaults.Maxit	= 5;
defaults.nT		= 10;%number of templates for the sparse representation
defaults.rel_std_afnv = [0.03,0.0005,0.0005,0.03,1,1];%diviation of the sampling of particle filter
defaults.n_sample	= 600;		%number of particles
defaults.sz_T		= [12,15];

parameters = struct();

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'parameters'
            parameters = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

state.parameters = struct_merge(parameters, defaults);
state.lambda = state.parameters.lambda;

% Initialize templates T
%-Generate T from single image
[x, y] = region2poly(region);
init_pos = [y([1, 2, 4]), x([1, 2, 4])]';

n_sample=state.parameters.n_sample;
sz_T=state.parameters.sz_T;
nT=state.parameters.nT;

[gray, ~] = image_convert(image_create(image), 'gray');

[state.T, T_norm, ~, T_std] = InitTemplates(sz_T,nT,gray,init_pos);
state.norms = T_norm.*T_std; %template norms
state.occlusionNf = 0;

dim_T	= size(state.T,1); % %number of elements in one template, sz_T(1)*sz_T(2)=12x15 = 180
state.A		= [state.T eye(dim_T)]; %data matrix is composed of T, positive trivial T.
state.alpha = 50;%this parameter is used in the calculation of the likelihood of particle filter
aff_obj = corners2affine(init_pos, sz_T); %get affine transformation parameters from the corner points in the first frame
state.map_aff = aff_obj.afnv;
state.aff_samples = ones(n_sample, 1) * state.map_aff;

state.T_id	= -(1:nT);	% template IDs, for debugging
state.fixT = state.T(:,1)/nT; % first template is used as a fixed template

%Temaplate Matrix
state.Temp = [state.A state.fixT];
state.Dict = state.Temp' * state.Temp;
state.Temp1 = [state.T, state.fixT] * pinv([state.T, state.fixT]);

location = region;
values = struct();

end
