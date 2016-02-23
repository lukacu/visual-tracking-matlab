function h = sfigure(h, varargin)
% SFIGURE  Create figure window (minus annoying focus-theft).
%
% Usage is identical to figure.
%
% Daniel Eaton, 2005
%% See also "help figure"
if nargin>=1
if ishandle(h)
    set(0, 'CurrentFigure', h);
else
    h = figure(h);
    %set(h); %, varargin{:});
end
else
    h = figure(); %varargin{:});
end