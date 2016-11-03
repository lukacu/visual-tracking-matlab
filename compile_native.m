function compile_native(varargin)

ocvdir = '';
mcvdir = fileparts(fileparts(which('cv.resize')));

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'opencv'
            ocvdir = varargin{i+1};
        case 'mexopencv'
            mcvdir = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

mcvincludes = fullfile(mcvdir, 'includes');
mcvlibs = fullfile(mcvdir, 'lib');
dir = fileparts(mfilename('fullpath'));

addpath(fullfile(dir, 'common'));

success = true;

dest = fullfile(dir, 'common', 'parts');
success = compile_mex('partassemble', {fullfile(dest, 'partassemble.cpp')}, 'Includes', {dest}, 'Directory', dest) & success;
success = compile_mex('partcompare', {fullfile(dest, 'partcompare.cpp')}, 'Includes', {dest}, 'Directory', dest) & success;

dest = fullfile(dir, 'ant', 'memory');
success = compile_mex('gradients', {fullfile(dest, 'gradients.cpp')}, 'Includes', {dest}, 'Directory', dest) & success;

dest = fullfile(dir, 'ivt');
success = compile_mex('interp2', {fullfile(dest, 'interp2.cpp')}, 'Includes', {dest}, 'Directory', dest) & success;

dest = fullfile(dir, 'l1apg');
success = compile_mex('imgaffine', {fullfile(dest, 'imgaffine.c')}, 'Includes', {dest}, 'Directory', dest) & success;

dest = fullfile(dir, 'meem');
success = compile_mex('im2colstep', {fullfile(dest, 'im2colstep.c')}, 'Includes', {dest}, 'Directory', dest) & success;
success = compile_mex('calcIIF', {fullfile(dest, 'calcIIF.cpp')}, 'Includes', {mcvincludes, fullfile(ocvdir, 'include')}, ...
    'Directory', dest, 'Libraries', {'opencv_core', 'opencv_imgproc', 'MxArray'}, 'LinkDirs', {mcvlibs, fullfile(ocvdir, 'lib')}) & success;

if ~success
	error('Unable to compile MEX files');
end

end
