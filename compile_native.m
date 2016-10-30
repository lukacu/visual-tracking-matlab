function compile_native()

dir = fileparts(mfilename('fullpath'));

addpath(fullfile(dir, 'common'));

success = true;

dest = fullfile(dir, 'common', 'parts');
success = compile_mex('partassemble', {fullfile(dest, 'partassemble.cpp')}, {dest}, dest) & success;
success = compile_mex('partcompare', {fullfile(dest, 'partcompare.cpp')}, {dest}, dest) & success;

dest = fullfile(dir, 'ant', 'memory');
success = compile_mex('gradients', {fullfile(dest, 'gradients.cpp')}, {dest}, dest) & success;

dest = fullfile(dir, 'ivt');
success = compile_mex('interp2', {fullfile(dest, 'interp2.cpp')}, {dest}, dest) & success;

if ~success
	error('Unable to compile MEX files');
end

end
