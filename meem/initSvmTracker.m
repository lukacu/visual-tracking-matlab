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

function [state] = initSvmTracker (state, sample, label, fuzzy_weight)

sample_w = fuzzy_weight;

pos_mask = label>0.5;
neg_mask = ~pos_mask;
s1 = sum(sample_w(pos_mask));
s2 = sum(sample_w(neg_mask));

sample_w(pos_mask) = sample_w(pos_mask)*s2;
sample_w(neg_mask) = sample_w(neg_mask)*s1;

C = max(state.svm_tracker.C*sample_w/sum(sample_w),0.001);

state.svm_tracker.clsf = svmtrain( sample, label,'boxconstraint',C,'autoscale','false');

state.svm_tracker.clsf.w = state.svm_tracker.clsf.Alpha'*state.svm_tracker.clsf.SupportVectors;
state.svm_tracker.w = state.svm_tracker.clsf.w;
state.svm_tracker.Bias = state.svm_tracker.clsf.Bias;
state.svm_tracker.sv_label = label(state.svm_tracker.clsf.SupportVectorIndices,:);
state.svm_tracker.sv_full = sample(state.svm_tracker.clsf.SupportVectorIndices,:);

state.svm_tracker.pos_sv = state.svm_tracker.sv_full(state.svm_tracker.sv_label>0.5,:);
state.svm_tracker.pos_w = ones(size(state.svm_tracker.pos_sv,1),1);
state.svm_tracker.neg_sv = state.svm_tracker.sv_full(state.svm_tracker.sv_label<0.5,:);
state.svm_tracker.neg_w = ones(size(state.svm_tracker.neg_sv,1),1);

% compute real margin
pos2plane = -state.svm_tracker.pos_sv*state.svm_tracker.w';
neg2plane = -state.svm_tracker.neg_sv*state.svm_tracker.w';
state.svm_tracker.margin = (min(pos2plane) - max(neg2plane))/norm(state.svm_tracker.w);

% calculate distance matrix
if size(state.svm_tracker.pos_sv,1)>1
    state.svm_tracker.pos_dis = squareform(pdist(state.svm_tracker.pos_sv));
else
    state.svm_tracker.pos_dis = inf;
end
state.svm_tracker.neg_dis = squareform(pdist(state.svm_tracker.neg_sv));

% intialize tracker state.experts
state.experts{1}.w = state.svm_tracker.w;
state.experts{1}.Bias = state.svm_tracker.Bias;
state.experts{1}.score = [];
state.experts{1}.snapshot = state.svm_tracker;

state.experts{2} = state.experts{1};
