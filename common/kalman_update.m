function [xnew, Vnew, loglik, VVnew] = kalman_update(A, C, Q, R, y, x, V, varargin)
% KALMAN_UPDATE Do a one step update of the Kalman filter
% [xnew, Vnew, loglik] = kalman_update(A, C, Q, R, y, x, V, ...)
%
% INPUTS:
% A - the system matrix
% C - the observation matrix 
% Q - the system covariance 
% R - the observation covariance
% y(:)   - the observation at time t
% x(:) - E[X | y(:, 1:t-1)] prior mean
% V(:,:) - Cov[X | y(:, 1:t-1)] prior covariance
%
% OPTIONAL INPUTS (string/value pairs [default in brackets])
% 'initial' - 1 means x and V are taken as initial conditions 
%             (so A and Q are ignored) [0]
%
% OUTPUTS (where X is the hidden state being estimated)
%  xnew(:) =   E[ X | y(:, 1:t) ] 
%  Vnew(:,:) = Var[ X(t) | y(:, 1:t) ]
%  VVnew(:,:) = Cov[ X(t), X(t-1) | y(:, 1:t) ]
%  loglik = log P(y(:,t) | y(:,1:t-1)) log-likelihood of innovatio

% set default params
initial = 0;

args = varargin;
for i=1:2:length(args)
  switch args{i}
   case 'initial', initial = args{i+1};
   otherwise, error(['unrecognized argument ' args{i}])
  end
end

if initial
  xpred = x;
  Vpred = V;
else
  xpred = A * x;
  Vpred = A * V * A' + Q;
end

e = y - C * xpred; % error (innovation)
S = C * Vpred * C' + R;
%Sinv = inv(S);
ss = length(V);
loglik = gaussian_prob(e, zeros(1, length(e)), S, 1);
K = Vpred * C' / S; % Kalman gain matrix
% If there is no observation vector, set K = zeros(ss).
xnew = xpred + K * e;
Vnew = (eye(ss) - K * C) * Vpred;
VVnew = (eye(ss) - K * C) * A * V;

end

function p = gaussian_prob(x, m, C, use_log)
% GAUSSIAN_PROB Evaluate a multivariate Gaussian density.
% p = gaussian_prob(X, m, C)
% p(i) = N(X(:,i), m, C) where C = covariance matrix and each COLUMN of x is a datavector

% p = gaussian_prob(X, m, C, 1) returns log N(X(:,i), m, C) (to prevents underflow).
%
% If X has size dxN, then p has size Nx1, where N = number of examples

if nargin < 4, use_log = 0; end

if length(m)==1 % scalar
  x = x(:)';
end
[d, N] = size(x);
%assert(length(m)==d); % slow
m = m(:);
M = m*ones(1,N); % replicate the mean across columns
denom = (2*pi)^(d/2)*sqrt(abs(det(C)));
mahal = sum(((x-M)' / C).*(x-M)',2);   % Chris Bregler's trick
if any(mahal<0)
  warning('mahal < 0 => C is not psd')
end
if use_log
  p = -0.5*mahal - log(denom);
else
  p = exp(-0.5*mahal) / (denom+eps);
end

end