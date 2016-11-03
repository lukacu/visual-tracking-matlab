%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Implemetation of the tracker described in paper
%	"MEEM: Robust Tracking via Multiple state.experts using Entropy Minimization", 
%   Jianming Zhang, Shugao Ma, Stan Sclaroff, ECCV, 2014
%	
%	Copyright (C) 2014 Jianming Zhang
%
%	This program is free software: you can redistribute it and/or modify
%	it under the terms of the GNU General Public License as published by
%	the Free Software Foundation, either version 3 of the License, or
%	(at your option) any later version.
%
%	This program is distributed in the hope that it will be useful,
%	but WITHOUT ANY WARRANTY; without even the implied warranty of
%	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%	GNU General Public License for more details.
%
%	You should have received a copy of the GNU General Public License
%	along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%	If you have problems about this software, please contact: jmzhang@bu.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function state = expertsDo(state, I_vf)

roi_reg = state.sampler.roi; 
roi_reg(3:4) = state.sampler.roi(3:4)-state.sampler.roi(1:2);

feature_map = imresize(I_vf,state.config.ratio,'nearest');
ratio_x = size(I_vf,2)/size(feature_map,2);
ratio_y = size(I_vf,1)/size(feature_map,1);
patterns = im2colstep(feature_map,[state.sampler.template_size(1:2), size(I_vf,3)],[1, 1, size(I_vf,3)]);

x_sz = size(feature_map,2)-state.sampler.template_size(2)+1;
y_sz = size(feature_map,1)-state.sampler.template_size(1)+1;
[X, Y] = meshgrid(1:x_sz,1:y_sz);
temp = repmat(state.svm_tracker.output,[numel(X),1]);
temp(:,1) = (X(:)-1)*ratio_x + state.sampler.roi(1);
temp(:,2) = (Y(:)-1)*ratio_y + state.sampler.roi(2);

% select expert
label_prior = fspecial('gaussian',[y_sz,x_sz], state.config.label_prior_sigma);
label_prior_neg = ones(size(label_prior))/numel(label_prior);

% compute log likelihood and entropy
n = numel(state.experts);
score_temp = zeros(n,1);
rect_temp = zeros(n,4);

rad = 0.5 * min(state.sampler.template_size(1:2));

mask_temp = zeros(y_sz,x_sz);
idx_temp = [];
svm_scores = [];
svm_score = {};
svm_density = {};
peaks_collection = {};
peaks = zeros(n,2);
peaks_pool = [];

for i = 1:n
    % find the highest peak
    svm_score{i} = -(state.experts{i}.w*patterns+state.experts{i}.Bias);
    svm_density{i} = normcdf(svm_score{i},0,1).*label_prior(:)';
    [val, idx] = max(svm_density{i});
    best_rect = temp(idx,:);
    rect_temp(i,:) = best_rect;
    svm_scores(i) = svm_score{i}(idx);
    idx_temp(i) = idx;
    [r c] = ind2sub(size(mask_temp),idx);
    peaks(i,:) = [r c];
    
    % find the possible peaks
    
    density_map = reshape(svm_density{i},y_sz,[]);
    density_map = (density_map - min(density_map(:)))/(max(density_map(:)) - min(density_map(:)));
    mm = (imdilate(density_map,strel('square',round(rad))) == density_map) & density_map > 0.9;
    [rn cn] = ind2sub(size(mask_temp),find(mm));
    peaks_pool = cat(1,peaks_pool,[rn cn]);  
    peaks_collection{i} = [rn cn];
end

% merg peaks
peaks = mergePeaks(peaks,rad);
peaks_pool = mergePeaks(peaks_pool,rad);
mask_temp(sub2ind(size(mask_temp),round(peaks(:,1)),round(peaks(:,2)))) = 1;

for i = 1:n

    dis = pdist2(peaks_pool,peaks_collection{i});
    [rr, cc] = ind2sub([size(peaks_pool,1),size(peaks_collection{i},1)],find(dis < rad));
    [~, ia, ~] = unique(cc);
    peaks_temp = peaks_pool;
    peaks_temp(rr(ia),:) = peaks_collection{i}(cc(ia),:);
    mask = zeros(size(mask_temp));
    mask(sub2ind(size(mask_temp),round(peaks_temp(:,1)),round(peaks_temp(:,2)))) = 1;
    mask = mask>0;

    [loglik, ent] = getLogLikelihoodEntropy(svm_score{i}(mask(:)),label_prior(mask(:)),label_prior_neg(mask(:)));

    state.experts{i}.score(end+1) =  loglik - state.config.expert_lambda * ent;
    score_temp(i) = sum(state.experts{i}.score(max(end+1-state.config.entropy_score_winsize,1):end));    
end

%
state.svm_tracker.best_expert_idx = numel(score_temp);
if numel(score_temp) >= 2 && state.config.use_experts
    [~, idx] = max(score_temp(1:end-1));
    if score_temp(idx) > score_temp(end) && size(peaks,1) > 1
        state.experts{end}.score = state.experts{idx}.score;
        state.svm_tracker = state.experts{idx}.snapshot;
        state.svm_tracker.best_expert_idx = idx;

    end
end
state.svm_tracker.output = rect_temp(state.svm_tracker.best_expert_idx,:);
state.svm_tracker.confidence = svm_scores(state.svm_tracker.best_expert_idx);
state.svm_tracker.output_exp = rect_temp(end,:);
state.svm_tracker.confidence_exp = svm_scores(end);

% update training sample
% approximately 200 training samples
step = round(sqrt((y_sz*x_sz)/120));
mask_temp = zeros(y_sz,x_sz);
mask_temp(1:step:end,1:step:end) = 1;
mask_temp = mask_temp > 0;
state.sampler.patterns_dt = patterns(:,mask_temp(:))';
state.sampler.state_dt = temp(mask_temp(:),:);
state.sampler.costs = 1 - getIOU(state.sampler.state_dt,state.svm_tracker.output);
if min(state.sampler.costs)~=0
    state.sampler.state_dt = [state.sampler.state_dt; rect_temp(state.svm_tracker.best_expert_idx,:)];
    state.sampler.patterns_dt = [state.sampler.patterns_dt; patterns(:,idx_temp(state.svm_tracker.best_expert_idx))'];
    state.sampler.costs = [state.sampler.costs;0];
end

end

function merged_peaks = mergePeaks(peaks, rad)

dis_mat = pdist2(peaks,peaks) + diag(inf*ones(size(peaks,1),1));
while min(dis_mat(:)) < rad && size(peaks,1) > 1
    [~, idx] = min(dis_mat(:));
    [id1, id2] = ind2sub(size(dis_mat),idx);
    merged_peak = 0.5*(peaks(id1,:) + peaks(id2,:));
    peaks([id1 id2],:) = [];
    peaks = [peaks;merged_peak];
    dis_mat = pdist2(peaks,peaks) + diag(inf*ones(size(peaks,1),1));
end

merged_peaks = peaks;

end

