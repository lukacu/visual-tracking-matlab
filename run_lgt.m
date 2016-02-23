function run_lgt(directory)

if exist(fullfile('+cv', 'calcHist.m'), 'file') == 0
    error('MexOpenCV not found!');
end

root_directory = fileparts(mfilename('fullpath'));

includes = {fullfile(root_directory, 'common'), ...
    fullfile(root_directory, 'lgt'), ...
    fullfile(root_directory, 'lgt', 'modalities'), ...
    fullfile(root_directory, 'common', 'parts')};

for i = 1:numel(includes)
    addpath(includes{i});
end;

if varargin < 1
    if exist('traxserver') ~= 3
		    error('Traxserver MEX file not found!');
    end
    trax('lgt', 'rectangle');
else
    [sequence, region] = scan_directory(directory);
    track('lgt', sequence, region);
end;
