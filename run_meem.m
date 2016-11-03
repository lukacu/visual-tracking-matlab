function run_meem(directory)

root_directory = fileparts(mfilename('fullpath'));

includes = {fullfile(root_directory, 'common'), ...
    fullfile(root_directory, 'meem')
};

for i = 1:numel(includes)
    addpath(includes{i});
end;

if nargin < 1
    if exist('traxserver') ~= 3
		    error('Traxserver MEX file not found!');
    end
    trax('meem', 'rectangle');
else
    [sequence, region] = scan_directory(directory);
    track('meem', sequence, region);
end;
