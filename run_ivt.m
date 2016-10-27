function run_lgt(directory)

root_directory = fileparts(mfilename('fullpath'));

includes = {fullfile(root_directory, 'common'), ...
    fullfile(root_directory, 'ivt')
};

for i = 1:numel(includes)
    addpath(includes{i});
end;

if nargin < 1
    if exist('traxserver') ~= 3
		    error('Traxserver MEX file not found!');
    end
    trax('ivt', 'rectangle');
else
    [sequence, region] = scan_directory(directory);
    track('ivt', sequence, region);
end;
