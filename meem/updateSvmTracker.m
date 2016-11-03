%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Implemetation of the tracker described in paper
%	"MEEM: Robust Tracking via Multiple Experts using Entropy Minimization", 
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

function state = updateSvmTracker(state, sample, label, fuzzy_weight)

sample = [state.svm_tracker.pos_sv;state.svm_tracker.neg_sv; sample];
label = [ones(size(state.svm_tracker.pos_sv,1),1);zeros(size(state.svm_tracker.neg_sv,1),1);label];% positive:1 negative:0
sample_w = [state.svm_tracker.pos_w;state.svm_tracker.neg_w;fuzzy_weight];
       
pos_mask = label>0.5;
neg_mask = ~pos_mask;
s1 = sum(sample_w(pos_mask));
s2 = sum(sample_w(neg_mask));
        
sample_w(pos_mask) = sample_w(pos_mask)*s2;
sample_w(neg_mask) = sample_w(neg_mask)*s1;
        
C = max(state.svm_tracker.C*sample_w/sum(sample_w),0.001);


    state.svm_tracker.clsf = svmtrain( sample, label, ...%'kernel_function',@kfun,'kfunargs',{state.svm_tracker.struct_mat},...
       'boxconstraint',C,'autoscale','false','options',statset('MaxIter',5000));

%**************************
state.svm_tracker.w = state.svm_tracker.clsf.Alpha'*state.svm_tracker.clsf.SupportVectors;
state.svm_tracker.Bias = state.svm_tracker.clsf.Bias;
state.svm_tracker.clsf.w = state.svm_tracker.w;
% get the idx of new svs
sv_idx = state.svm_tracker.clsf.SupportVectorIndices;
sv_old_sz = size(state.svm_tracker.pos_sv,1)+size(state.svm_tracker.neg_sv,1);
sv_new_idx = sv_idx(sv_idx>sv_old_sz);
sv_new = sample(sv_new_idx,:);
sv_new_label = label(sv_new_idx,:);
        
num_sv_pos_new = sum(sv_new_label);
        
% update pos_dis, pos_w and pos_sv
pos_sv_new = sv_new(sv_new_label>0.5,:);
if ~isempty(pos_sv_new)
    if size(pos_sv_new,1)>1
        pos_dis_new = squareform(pdist(pos_sv_new));
    else
        pos_dis_new = 0;
    end
    pos_dis_cro = pdist2(state.svm_tracker.pos_sv,pos_sv_new);
    state.svm_tracker.pos_dis = [state.svm_tracker.pos_dis, pos_dis_cro; pos_dis_cro', pos_dis_new];
    state.svm_tracker.pos_sv = [state.svm_tracker.pos_sv;pos_sv_new];
    state.svm_tracker.pos_w = [state.svm_tracker.pos_w;ones(num_sv_pos_new,1)];
end
        
% update neg_dis, neg_w and neg_sv
neg_sv_new = sv_new(sv_new_label<0.5,:);
if ~isempty(neg_sv_new)
    if size(neg_sv_new,1)>1
        neg_dis_new = squareform(pdist(neg_sv_new));
    else
        neg_dis_new = 0;
    end
    neg_dis_cro = pdist2(state.svm_tracker.neg_sv,neg_sv_new);
    state.svm_tracker.neg_dis = [state.svm_tracker.neg_dis, neg_dis_cro; neg_dis_cro', neg_dis_new];
    state.svm_tracker.neg_sv = [state.svm_tracker.neg_sv;neg_sv_new];
    state.svm_tracker.neg_w = [state.svm_tracker.neg_w;ones(size(sv_new,1)-num_sv_pos_new,1)];
end
        
state.svm_tracker.pos_dis = state.svm_tracker.pos_dis + diag(inf*ones(size(state.svm_tracker.pos_dis,1),1));
state.svm_tracker.neg_dis = state.svm_tracker.neg_dis + diag(inf*ones(size(state.svm_tracker.neg_dis,1),1));
        
        
% compute real margin
pos2plane = -state.svm_tracker.pos_sv*state.svm_tracker.w';
neg2plane = -state.svm_tracker.neg_sv*state.svm_tracker.w';
state.svm_tracker.margin = (min(pos2plane) - max(neg2plane))/norm(state.svm_tracker.w);
        
% shrink svs
% check if to remove
if size(state.svm_tracker.pos_sv,1)+size(state.svm_tracker.neg_sv,1)>state.svm_tracker.B
    pos_score_sv = -(state.svm_tracker.pos_sv*state.svm_tracker.w'+state.svm_tracker.Bias);
    neg_score_sv = -(state.svm_tracker.neg_sv*state.svm_tracker.w'+state.svm_tracker.Bias);
    m_pos = abs(pos_score_sv) < state.svm_tracker.m2;
    m_neg = abs(neg_score_sv) < state.svm_tracker.m2;
            
    if sum(m_pos) > 0
        state.svm_tracker.pos_sv = state.svm_tracker.pos_sv(m_pos,:);
        state.svm_tracker.pos_w = state.svm_tracker.pos_w(m_pos,:);
        state.svm_tracker.pos_dis = state.svm_tracker.pos_dis(m_pos,m_pos);
    end

    if sum(m_neg)>0
        state.svm_tracker.neg_sv = state.svm_tracker.neg_sv(m_neg,:);
        state.svm_tracker.neg_w = state.svm_tracker.neg_w(m_neg,:);
        state.svm_tracker.neg_dis = state.svm_tracker.neg_dis(m_neg,m_neg);
    end
end
        
% check if to merge
while size(state.svm_tracker.pos_sv,1)+size(state.svm_tracker.neg_sv,1)>state.svm_tracker.B
    [mm_pos,idx_pos] = min(state.svm_tracker.pos_dis(:));
    [mm_neg,idx_neg] = min(state.svm_tracker.neg_dis(:));
            
    if mm_pos > mm_neg || size(state.svm_tracker.pos_sv,1) <= state.svm_tracker.B_p% merge negative samples
  
        [i,j] = ind2sub(size(state.svm_tracker.neg_dis),idx_neg);
        w_i= state.svm_tracker.neg_w(i);
        w_j= state.svm_tracker.neg_w(j);
        merge_sample = (w_i*state.svm_tracker.neg_sv(i,:)+w_j*state.svm_tracker.neg_sv(j,:))/(w_i+w_j);                
                
        state.svm_tracker.neg_sv([i,j],:) = []; state.svm_tracker.neg_sv(end+1,:) = merge_sample;
        state.svm_tracker.neg_w([i,j]) = []; state.svm_tracker.neg_w(end+1,1) = w_i + w_j;
                
        state.svm_tracker.neg_dis([i,j],:)=[]; state.svm_tracker.neg_dis(:,[i,j])=[];
        neg_dis_cro = pdist2(state.svm_tracker.neg_sv(1:end-1,:),merge_sample);
        state.svm_tracker.neg_dis = [state.svm_tracker.neg_dis, neg_dis_cro;neg_dis_cro',inf];                
    else
        [i,j] = ind2sub(size(state.svm_tracker.pos_dis),idx_pos);
        w_i= state.svm_tracker.pos_w(i);
        w_j= state.svm_tracker.pos_w(j);
        merge_sample = (w_i*state.svm_tracker.pos_sv(i,:)+w_j*state.svm_tracker.pos_sv(j,:))/(w_i+w_j);                

        state.svm_tracker.pos_sv([i,j],:) = []; state.svm_tracker.pos_sv(end+1,:) = merge_sample;
        state.svm_tracker.pos_w([i,j]) = []; state.svm_tracker.pos_w(end+1,1) = w_i + w_j;
                
        state.svm_tracker.pos_dis([i,j],:)=[]; state.svm_tracker.pos_dis(:,[i,j])=[];
        pos_dis_cro = pdist2(state.svm_tracker.pos_sv(1:end-1,:),merge_sample);
        state.svm_tracker.pos_dis = [state.svm_tracker.pos_dis, pos_dis_cro;pos_dis_cro',inf]; 
                
                
    end
            
end
        
% update experts
state.experts{end}.w = state.svm_tracker.w;
state.experts{end}.Bias = state.svm_tracker.Bias;
        
state.svm_tracker.update_count = state.svm_tracker.update_count + 1;
