function run_l1apg(directory)

root_directory = fileparts(mfilename('fullpath'));

includes = {fullfile(root_directory, 'common'), ...
    fullfile(root_directory, 'l1apg')
};

for i = 1:numel(includes)
    addpath(includes{i});
end;

if nargin < 1
    if exist('traxserver') ~= 3
		    error('Traxserver MEX file not found!');
    end
    trax('l1apg', 'polygon');
else
    [sequence, region] = scan_directory(directory);
    track('l1apg', sequence, region);
end;
