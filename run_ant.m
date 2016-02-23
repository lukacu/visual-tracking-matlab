function run_ant(directory)

if exist(fullfile('+cv', 'calcHist.m'), 'file') == 0
    error('MexOpenCV not found!');
end

root_directory = fileparts(mfilename('fullpath'));

includes = {fullfile(root_directory, 'common'), ...
    fullfile(root_directory, 'ant'), ...
    fullfile(root_directory, 'ant', 'memory'), ...
    fullfile(root_directory, 'ant', 'segmentation'), ...
    fullfile(root_directory, 'common', 'parts')};

for i = 1:numel(includes)
    addpath(includes{i});
end;

if nargin < 1
    if exist('traxserver') ~= 3
		    error('Traxserver MEX file not found!');
    end
    trax('ant', 'rectangle');
else
    [sequence, region] = scan_directory(directory);
    track('ant', sequence, region);
end;
