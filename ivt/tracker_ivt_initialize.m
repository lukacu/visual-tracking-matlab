function [state, location, values] = tracker_ivt_initialize(image, region, varargin)

bbox = region; % region([2 1 4 3]);

% TODO: use polygon instead of rectangle
p = [bbox(1) + bbox(3) / 2, bbox(2) + bbox(4) / 2, bbox(3), bbox(4), 0];

% TODO: parameters merging
state.opt = struct('numsample',600, 'condenssig', 0.2, 'ff', .95, 'batchsize',5, 'affsig',[4,4,.01,.01,.002,.001]);

state.param0 = [p(1), p(2), p(3)/32, p(5), p(4)/p(3), 0];
state.param0 = affparam2mat(state.param0);

rng(0);

if size(image, 3) > 1
    image = rgb2gray(image);
end;

image = double(image)/256;

if ~isfield(state.opt,'tmplsize')   state.opt.tmplsize = [32,32];  end
if ~isfield(state.opt,'numsample')  state.opt.numsample = 400;  end
if ~isfield(state.opt,'affsig')     state.opt.affsig = [4,4,.02,.02,.005,.001];  end
if ~isfield(state.opt,'condenssig') state.opt.condenssig = 0.01;  end

if ~isfield(state.opt,'maxbasis')   state.opt.maxbasis = 16;  end
if ~isfield(state.opt,'batchsize')  state.opt.batchsize = 5;  end
if ~isfield(state.opt,'errfunc')    state.opt.errfunc = 'L2';  end
if ~isfield(state.opt,'ff')         state.opt.ff = 1.0;  end
if ~isfield(state.opt,'minopt')
    state.opt.minopt = optimset; state.opt.minopt.MaxIter = 25; state.opt.minopt.Display='off';
end

state.template.mean = warpimg(image, state.param0, state.opt.tmplsize);

state.template.basis = [];
state.template.eigval = [];
state.template.numsample = 0;
state.template.reseig = 0;
sz = size(state.template.mean);
state.N = sz(1)*sz(2);

state.param = [];
state.param.est = state.param0;
state.param.wimg = state.template.mean;
%pts = [];

state.wimgs = [];

values = struct();
location = region;

end
