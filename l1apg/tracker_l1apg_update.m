function [state, location, values] = tracker_l1apg_update(state, image, varargin)

values = struct();

[gray, ~] = image_convert(image_create(image), 'gray');

%-Draw transformation samples from a Gaussian distribution
sc			= sqrt(sum(state.map_aff(1:4).^2)/2);
std_aff		= state.parameters.rel_std_afnv.*[1, sc, sc, 1, sc, sc];
state.map_aff		= state.map_aff + 1e-14;
state.aff_samples = draw_sample(state.aff_samples, std_aff); %draw transformation samples from a Gaussian distribution

%-Crop candidate targets "Y" according to the transformation samples
[Y, Y_inrange] = crop_candidates(im2double(gray), state.aff_samples(:,1:6), state.parameters.sz_T);
if(sum(Y_inrange==0) == state.parameters.n_sample)
    sprintf('Target is out of the frame!\n');
end

[Y, ~, ~] = whitening(Y);	 % zero-mean-unit-variance
[Y, ~] = normalizeTemplates(Y); %norm one

%-L1-LS for each candidate target
eta_max	= -inf;
q   = zeros(state.parameters.n_sample,1); % minimal error bound initialization

% first stage L2-norm bounding
for j = 1:state.parameters.n_sample
    if Y_inrange(j)==0 || sum(abs(Y(:,j)))==0
        continue;
    end
    
    % L2 norm bounding
    q(j) = norm(Y(:,j)-state.Temp1*Y(:,j));
    q(j) = exp(-state.alpha*q(j)^2);
end
%  sort samples according to descend order of q
[q,indq] = sort(q,'descend');

% second stage
p	= zeros(state.parameters.n_sample,1); % observation likelihood initialization
n = 1;
tau = 0;
while (n<state.parameters.n_sample)&&(q(n)>=tau)
    
    [c] = APGLASSOup(state.Temp' * Y(:, indq(n)), state.Dict, state.parameters, state.lambda);
    
    D_s = (Y(:,indq(n)) - [state.A(:,1:state.parameters.nT) state.fixT]*[c(1:state.parameters.nT); c(end)]).^2;%reconstruction error
    p(indq(n)) = exp(-state.alpha*(sum(D_s))); % probability w.r.t samples
    tau = tau + p(indq(n))/(2*state.parameters.n_sample-1);%update the threshold
    
    if(sum(c(1:state.parameters.nT))<0) %remove the inverse intensity patterns
        continue;
    elseif(p(indq(n))>eta_max)
        id_max	= indq(n);
        c_max	= c;
        eta_max = p(indq(n));
    end
    n = n+1;
end

% resample according to probability
map_aff = state.aff_samples(id_max,1:6); %target transformation parameters with the maximum probability
a_max	= c_max(1:state.parameters.nT);
[state.aff_samples, ~] = resample(state.aff_samples,p,map_aff); %resample the samples wrt. the probability
[~, indA] = max(a_max);
min_angle = images_angle(Y(:,id_max),state.A(:,indA));

%-Template update
state.occlusionNf = state.occlusionNf-1;
level = 0.03;
if( min_angle > state.parameters.angle_threshold && state.occlusionNf<0 )
    trivial_coef = c_max(state.parameters.nT+1:end-1);
    trivial_coef = reshape(trivial_coef, state.parameters.sz_T);
    
    trivial_coef = im2bw(trivial_coef, level);
    
    se = [0 0 0 0 0;
        0 0 1 0 0;
        0 1 1 1 0;
        0 0 1 0 0'
        0 0 0 0 0];
    trivial_coef = imclose(trivial_coef, se);
    
    cc = bwconncomp(trivial_coef);
    stats = regionprops(cc, 'Area');
    areas = [stats.Area];
    
    % occlusion detection
    if (max(areas) < round(0.25 * prod(state.parameters.sz_T)))
        % find the tempalte to be replaced
        [~,indW] = min(a_max(1:state.parameters.nT));
        
        % insert new template
        state.T(:,indW)	= Y(:,id_max);
        %T_mean(indW)= Y_crop_mean(id_max);
        %T_id(indW)	= t; %track the replaced template for debugging
        %norms(indW) = Y_crop_std(id_max)*Y_crop_norm(id_max);
        
        [state.T, ~] = normalizeTemplates(state.T);
        state.A(:,1:state.parameters.nT)	= state.T;
        
        %Temaplate Matrix
        state.Temp = [state.A state.fixT];
        state.Dict = state.Temp' * state.Temp;
        state.Temp1 = [state.T,state.fixT]*pinv([state.T,state.fixT]);
    else
        state.occlusionNf = 5;
        % update L2 regularized term
        state.lambda(3) = 0;
    end
elseif state.occlusionNf<0
    state.lambda(3) = state.parameters.lambda(3);
end

points = aff2image(map_aff', state.parameters.sz_T);
location = points2rect([points(2:2:end), points(1:2:end)]');
end