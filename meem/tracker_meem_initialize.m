function [state, location, values] = tracker_meem_initialize(image, region, varargin)

warning('off','MATLAB:maxNumCompThreads:Deprecated');
maxNumCompThreads(1);% The rounding error due to using differen number of threads
                     % could cause different tracking results.  On most sequences,
                     % the difference is very small, while on some challenging
                     % sequences, the difference can be substantial due to
                     % "butterfly effects". Therefore, we suggest using
                     % Spatial Robustness Evaluation (SRE) to benchmark
                     % trackers.

defaults.search_roi = 2; % ratio of the search roi to tracking window
defaults.padding = 40; % for object out of border

defaults.debug = false;
defaults.verbose = false;
defaults.use_experts = true;
defaults.use_color = true;
defaults.use_raw_feat = false; % raw intensity feature value
defaults.use_iif = true; % use illumination invariant feature

defaults.svm_thresh = -0.7; % for detecting the tracking failure
defaults.max_expert_sz = 4;
defaults.expert_update_interval = 50;
defaults.update_count_thresh = 1;
defaults.entropy_score_winsize = 5;
defaults.expert_lambda = 10;
defaults.label_prior_sigma = 15;

defaults.hist_nbin = 32; % histogram bins for iif computation

defaults.thresh_p = 0.1; % IOU threshold for positive training samples
defaults.thresh_n = 0.5; % IOU threshold for negative ones

parameters = struct();

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'parameters'
            parameters = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

% intialization
init_rect = round(region);
state.config = struct_merge(parameters, defaults);

[frame, ~] = image_convert(image_create(image), 'rgb');

thr_n = 5;
state.config.thr = (1/thr_n:1/thr_n:1-1/thr_n)*255;
state.config.fd = numel(state.config.thr);

% decide image scale and pixel step for sampling feature
% rescale raw input frames propoerly would save much computation
frame_min_width = 320;
trackwin_max_dimension = 64;
template_max_numel = 144;
frame_sz = size(frame);

if max(init_rect(3:4)) <= trackwin_max_dimension ||...
        frame_sz(2) <= frame_min_width
    state.config.image_scale = 1;
else
    min_scale = frame_min_width/frame_sz(2);
    state.config.image_scale = max(trackwin_max_dimension/max(init_rect(3:4)),min_scale);
end
wh_rescale = init_rect(3:4) * state.config.image_scale;
win_area = prod(wh_rescale);
state.config.ratio = (sqrt(template_max_numel/win_area));
template_sz = round(wh_rescale * state.config.ratio);
state.config.template_sz = template_sz([2 1]);

state.sampler = createSampler();
state.svm_tracker = createSvmTracker();
state.experts = {};

state.svm_tracker.output = init_rect * state.config.image_scale;
state.svm_tracker.output(1:2) = state.svm_tracker.output(1:2) + state.config.padding;
state.svm_tracker.output_exp = state.svm_tracker.output;

state.output = state.svm_tracker.output;

I_scale = frame;

% compute ROI and scale image
if state.config.image_scale ~= 1
    I_scale = cv.resize(I_scale, state.config.image_scale, state.config.image_scale);
end

if state.config.padding > 0
    I_scale = padarray(I_scale, [state.config.padding, state.config.padding], 'replicate');
end

state.sampler.roi = rsz_rt(state.svm_tracker.output, size(I_scale), 5 * state.config.search_roi, false);

I_crop = I_scale(round(state.sampler.roi(2):state.sampler.roi(4)),round(state.sampler.roi(1):state.sampler.roi(3)),:);

% compute feature images
[BC, ~] = getFeatureRep(I_crop, state.config);

% tracking part

state = initSampler(state, state.svm_tracker.output, BC, state.config);
train_mask = (state.sampler.costs < state.config.thresh_p) | (state.sampler.costs >= state.config.thresh_n);
label = state.sampler.costs(train_mask,1) < state.config.thresh_p;
fuzzy_weight = ones(size(label));
state = initSvmTracker(state, state.sampler.patterns_dt(train_mask,:), label, fuzzy_weight);

state.time = 0;

location = region;
values = struct();

end
