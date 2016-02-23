function [sequence, region] = scan_directory(dir, offset)
% SCAN_DIRECTORY scans a directory for images matching the following
% pattern:
%   00000001.jpg, 00000002.jpg, 00000003.jpg ...
% and returns an ordered cell array of the full file paths to the
% available images that form a video sequence.

sequence = cell(0, 0);

if nargin < 2
   offset = 1; 
end

i = offset;

mask = '%08d.jpg';

region = [];

while true
    
    image_name = sprintf(mask, i);

    if ~exist(fullfile(dir, image_name), 'file')
        break;
    end;

    sequence{i-offset+1} = fullfile(dir, image_name);

    i = i + 1;    
    
end;

if exist(fullfile(dir, 'groundtruth.txt'), 'file')
    trajectory = csvread(fullfile(dir, 'groundtruth.txt'));
    
    region = trajectory(offset, :);
end;