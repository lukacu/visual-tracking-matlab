function [state, location, values] = tracker_ivt_update(state, image)

if size(image, 3) > 1
    image = rgb2gray(image);
end;

image = double(image)/256;

% do tracking
state.param = estwarp_condens(image, state.template, state.param, state.opt);
% do update
state.wimgs = [state.wimgs, state.param.wimg(:)];
if (size(state.wimgs,2) >= state.opt.batchsize)
    if (isfield(state.param,'coef'))
        ncoef = size(state.param.coef,2);
        recon = repmat(state.template.mean(:),[1,ncoef]) + state.template.basis * state.param.coef;
        [state.template.basis, state.template.eigval, state.template.mean, state.template.numsample] = ...
            sklm(state.wimgs, state.template.basis, state.template.eigval, state.template.mean, state.template.numsample, state.opt.ff);
        state.param.coef = state.template.basis'*(recon - repmat(state.template.mean(:),[1,ncoef]));
    else
        [state.template.basis, state.template.eigval, state.template.mean, state.template.numsample] = ...
            sklm(state.wimgs, state.template.basis, state.template.eigval, state.template.mean, state.template.numsample, state.opt.ff);
    end
    state.wimgs = [];
    
    if (size(state.template.basis,2) > state.opt.maxbasis)
        state.template.reseig = state.opt.ff * state.template.reseig + sum(state.template.eigval(state.opt.maxbasis+1:end));
        state.template.basis  = state.template.basis(:,1:state.opt.maxbasis);
        state.template.eigval = state.template.eigval(1:state.opt.maxbasis);
        if (isfield(state.param,'coef'))
            state.param.coef = state.param.coef(1:state.opt.maxbasis,:);
        end
    end
end

sz = size(state.template.mean);
p = state.param.est;
w = sz(1);
h = sz(1);

M = [p(1) p(3) p(4); p(2) p(5) p(6)];

corners = [ 1,-w/2,-h/2; 1,w/2,-h/2; 1,w/2,h/2; 1,-w/2,h/2; 1,-w/2,-h/2 ]';
corners = M * corners;

x = min(corners(1,:));
y = min(corners(2,:));
width = max(corners(1,:)) - x;
height = max(corners(2,:)) - y;

location = [x, y, width, height];
values = struct();

end

