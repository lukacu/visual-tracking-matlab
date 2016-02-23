function [varargout] = rectangle_operation(operation, varargin)

switch lower(operation)
    case 'offset'
        narginchk(3, 4);
        nargoutchk(1, 1);
        
        rect = varargin{1};
        
        if nargin > 3
            offset = [varargin{2}, varargin{3}];
        else
            offset = varargin{2};
        end;
        
        varargout{1} = [rect(1:2) + offset, rect(3:4)];
        
    case 'recenter'
        narginchk(2, 4);
        nargoutchk(1, 1);
        
        rect = varargin{1};
        
        if nargin == 2

            varargout{1} = [- rect(3:4) / 2, rect(3:4)];

        else

            if nargin > 3
                offset = [varargin{2}, varargin{3}];
            else
                offset = varargin{2};
            end;

            varargout{1} = [rect(1:2) - offset - rect(3:4) / 2, rect(3:4)];

        end

    case 'expand'
        narginchk(3, 4);
        nargoutchk(1, 1);
        
        rect = varargin{1};
        
        if nargin > 3
            expand = [varargin{2}, varargin{3}];
        else
            expand = varargin{2};
        end;
        
        varargout{1} = [rect(1:2) - expand, rect(3:4) + 2 * expand];        

    case 'scale'
        narginchk(3, 4);
        nargoutchk(1, 1);
        
        rect = varargin{1};
        
        if nargin > 3
            scale = [varargin{2}, varargin{3}];
        else
            scale = varargin{2};
        end;
        
        varargout{1} = [rect(1:2) + rect(3:4) * ( 1 - scale ) / 2, rect(3:4) * scale];  
        
    case 'deal'
        narginchk(2, 2);
        nargoutchk(4, 4);
        
        rect = varargin{1};
                
        varargout{1} = rect(1);  
        varargout{2} = rect(2);
        varargout{3} = rect(3);
        varargout{4} = rect(4);

    case 'getcenter'
        narginchk(2, 2);
        nargoutchk(1, 1);
        
        rect = varargin{1};
                
        varargout{1} = rect(1:2) + rect(3:4) / 2;

    case 'setcenter'
        narginchk(2, 4);
        nargoutchk(1, 1);
        
        rect = varargin{1};
        
        if nargin == 2

            varargout{1} = [- rect(3:4) / 2, rect(3:4)];

        else

            if nargin > 3
                offset = [varargin{2}, varargin{3}];
            else
                offset = varargin{2};
            end;

            varargout{1} = [offset - rect(3:4) / 2, rect(3:4)];

        end

    case 'plot'
        narginchk(2, 500);
        nargoutchk(0, 0);
        
        rect = varargin{1};
        plotarg = varargin(2:end);
        
        points = rect2points(rect);
        plotc(points(:, 1), points(:, 2), plotarg{:});
        
        
    case 'max'
        narginchk(1, 500);
        nargoutchk(1, 1);
        
        all = cell2mat(varargin');

        x1 = min(all(:, 1));
        y1 = min(all(:, 2));
        x2 = max(all(:, 3) + all(:, 1));
        y2 = max(all(:, 4) + all(:, 2));
        
        varargout{1} = [x1, y1, x2 - x1, y2 - y1];
        
    case 'min'
        narginchk(1, 500);
        nargoutchk(1, 1);
        
        all = cell2mat(varargin{1:end});

        x1 = max(all(:, 1));
        y1 = max(all(:, 2));
        x2 = min(all(:, 3) + all(:, 1));
        y2 = min(all(:, 4) + all(:, 2));
        
        varargout{1} = [x1, y1, max(0, x2 - x1), max(0, y2 - y1)]; 

    case 'setsize'
        narginchk(3, 4);
        nargoutchk(1, 1);
        
        rect = varargin{1};

        if nargin > 3
            s = [varargin{2}, varargin{3}];
        else
            s = varargin{2};
            if numel(s) == 1
                s = [s, s];
            end;
        end;

        center = rectangle_operation('getcenter', rect);
        
        origin = [0, 0, s];
        
        varargout{1} = rectangle_operation('setcenter', origin, center);


    otherwise
        error('Unknown operation');
        
end