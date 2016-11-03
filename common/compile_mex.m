function [success] = compile_mex(name, files, varargin)

    directory = pwd;
    includes = {};
    linkdirs = {};
    libraries = {};

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'directory'
                directory = varargin{i+1};
            case 'includes'
                includes = varargin{i+1};
            case 'linkdirs'
                linkdirs = varargin{i+1};                
            case 'libraries'
                libraries = varargin{i+1};
            otherwise
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end


    function datenum = file_timestamp(filename)
        if ~exist(filename, 'file')
            datenum = 0;
            return;
        end;
        file_description = dir(filename);
        datenum = file_description.datenum;
    end

    mexname = fullfile(directory, [name, '.', mexext]);

    if exist(mexname, 'file') > 1

        function_timestamp = file_timestamp(mexname);

        older = cellfun(@(x) file_timestamp(x) < function_timestamp, files, 'UniformOutput', true);

        if all(older)
        
            success = true;
            return;
        end;
    end

    arguments = {};

    if nargin < 3
        includes = cell(0);
    end

    if nargin < 4
        directory = '';
    end;

    includes = cellfun(@(x) sprintf('-I%s', x), includes, 'UniformOutput', false);

    linkdirs = cellfun(@(x) sprintf('-L%s', x), linkdirs, 'UniformOutput', false);

    libraries = cellfun(@(x) sprintf('-l%s', x), libraries, 'UniformOutput', false);
    
    old_dir = pwd;

    try

        if ~isempty(directory)
            cd(directory)
        end;

        if is_octave() 

            mkoctfile('-mex', '-o', name, includes{:}, linkdirs{:}, libraries{:}, files{:}, arguments{:});

        else

            mex('-output', name, includes{:}, linkdirs{:}, libraries{:}, files{:}, arguments{:});

        end

        cd(old_dir);

        success = true;

    catch e

        cd(old_dir);
        fprintf('ERROR: Unable to compile MEX function: "%s".', e.message);
        success = false;

    end
    
end
