function [state, location, values] = tracker_meem_update(state, image, varargin)

    values = struct();

    state.time = state.time + 1;
    
	[frame, ~] = image_convert(image_create(image), 'rgb');

    % compute ROI and scale image
    if state.config.image_scale ~= 1
        I_scale = cv.resize(frame, state.config.image_scale, state.config.image_scale);
    end

    if state.config.padding > 0
        I_scale = padarray(frame, [state.config.padding, state.config.padding], 'replicate');
    end

    state.sampler.roi = rsz_rt(state.output, size(I_scale), state.config.search_roi, true);

    I_crop = I_scale(round(state.sampler.roi(2):state.sampler.roi(4)),round(state.sampler.roi(1):state.sampler.roi(3)),:);

    % compute feature images
    [BC, ~] = getFeatureRep(I_crop, state.config);

    % tracking part

    if mod(state.time, state.config.expert_update_interval) == 0 % svm_tracker.update_count >= config.update_count_thresh
        if numel(state.experts) < state.config.max_expert_sz
            state.svm_tracker.update_count = 0;
            state.experts{end}.snapshot = state.svm_tracker;
            state.experts{end+1} = state.experts{end};
        else
            state.svm_tracker.update_count = 0;
            state.experts{end}.snapshot = state.svm_tracker;
            state.experts(1:end-1) = state.experts(2:end);
        end
    end

    state = expertsDo(state, BC);

    if state.svm_tracker.confidence > state.config.svm_thresh
        state.output = state.svm_tracker.output;
    end

    % update svm classifier
    state.svm_tracker.temp_count = state.svm_tracker.temp_count + 1;

    if state.svm_tracker.confidence > state.config.svm_thresh %&& ~svm_tracker.failure
        train_mask = (state.sampler.costs < state.config.thresh_p) | (state.sampler.costs >= state.config.thresh_n);
        label = state.sampler.costs(train_mask) < state.config.thresh_p;

        skip_train = false;
        if state.svm_tracker.confidence > 1.0
            score_ = -(state.sampler.patterns_dt(train_mask,:) * state.svm_tracker.w' + state.svm_tracker.Bias);
            if prod(double(score_(label) > 1)) == 1 && prod(double(score_(~label)<1)) == 1
                skip_train = true;
            end
        end

        if ~skip_train
            costs = state.sampler.costs(train_mask);
            fuzzy_weight = ones(size(label));
            fuzzy_weight(~label) = 2*costs(~label)-1;
            state = updateSvmTracker(state, state.sampler.patterns_dt(train_mask,:), label, fuzzy_weight);
        end
    else
        state.svm_tracker.update_count = 0;
    end

    res = state.output;
    res(1:2) = res(1:2) - state.config.padding;
    location = res / state.config.image_scale;

end
