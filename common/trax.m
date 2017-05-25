function trax(tracker, format, varargin)

%cleanup = onCleanup(@() exit() );

RandStream.setGlobalStream(RandStream('mt19937ar', 'Seed', sum(clock)));

if nargin == 1
	format = 'rectangle';
end

traxserver('setup', format, {'path', 'memory', 'buffer'});

tracker_initialize = str2func(['tracker_', tracker, '_initialize']);
tracker_update = str2func(['tracker_', tracker, '_update']);

state = [];

try

    while 1

        [image, region, parameters] = traxserver('wait');

        if isempty(image)
            break;
        end;

        args = {};

        if ~isempty(parameters) && iscell(parameters)
            args{1} = 'parameters';
            args{2} = cell2struct(parameters);
        end;

		if ischar(image)
        	I = imread(image);
		elseif isa(image,'uint8')
			I = image;
		elseif isstruct(image)
			I = cv.imdecode(image.data, 'Color', true);
		else
			error('Invalid image type');
		end;


        if isempty(region)
            if isempty(state)
                break;
            end;

            [state, location, values] = tracker_update(state, I, args{:});

        else

            [state, location, values] = tracker_initialize(I, region, args{:});

        end


        if isempty(location)
            location = [0, 0, 1, 1];
        end;

        location = location(:)';

        if (isstruct(values))
            traxserver('status', location, values);
        else
            traxserver('status', location);
        end
    end

catch err
    disp(getReport(err,'extended'));
end

end

function [S] = cell2struct(A)

    [N, V] = size(A);

    S = struct();

    if ~iscell(A) || V ~= 2 || N < 1
        return;
    end;

    for i = 1:N
        try
            if isnan(str2double(A{i, 2}))
                eval(sprintf('S.%s = ''%s'';', A{i, 1}, A{i, 2}));
            else
                eval(sprintf('S.%s = %f;', A{i, 1}, str2double(A{i, 2})));
            end
        catch err
            disp(err);
        end
    end;

end


