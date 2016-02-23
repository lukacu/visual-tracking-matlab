function [varargout] = polygon_operation(operation, varargin)

switch lower(operation)
    case 'offset'
        narginchk(3, 4);
        nargoutchk(1, 1);
        
        poly = varargin{1};
        
        if nargin > 3
            offset = [varargin{2}, varargin{3}];
        else
            offset = varargin{2};
        end;
        
        [x, y] = polygon_operation('deal', poly);
                
        varargout{1} = polygon_operation('pack', x + offset(1), y + offset(2));

    case 'scale'
        narginchk(3, 4);
        nargoutchk(1, 1);
        
        poly = varargin{1};
        
        if nargin > 3
            sx = varargin{2};
            sy = varargin{3};
        else
            sx = varargin{2};
            sy = varargin{2};
        end;

        [x, y] = polygon_operation('deal', poly);

        [cx, cy] = polygon_operation('getcenter', poly);
        
        varargout{1} = polygon_operation('pack', ((x - cx) * sx) + cx, ...
            ((y - cy) * sy) + cy);
        
    case 'deal'
        narginchk(2, 2);
        nargoutchk(2, 2);
        
        poly = varargin{1};
                
        varargout{1} = poly(1:2:end);  
        varargout{2} = poly(2:2:end);
        
    case 'pack'
        narginchk(3, 3);
        nargoutchk(1, 1);
        
        x = varargin{1}(:);
        y = varargin{2}(:);
        poly = [x, y]';
        varargout{1} = poly(:);  

    case 'getcenter'
        narginchk(2, 2);
        nargoutchk(1, 2);
        
        poly = varargin{1};
                
        if nargout == 1
            varargout{1} = [mean(poly(1:2:end)), mean(poly(2:2:end))];
        else
            varargout{1} = mean(poly(1:2:end));
            varargout{2} = mean(poly(2:2:end));
        end
        
    case 'setcenter'
        narginchk(2, 4);
        nargoutchk(1, 1);
        
        poly = varargin{1};
        
        if nargin == 2

            ox = 0;
            oy = 0;

        else

            if nargin > 3
                ox = varargin{2};
                oy = varargin{3};
            else
                ox = varargin{2}(1);
                oy = varargin{2}(2);
            end;

        end
        
        [x, y] = polygon_operation('deal', poly);

        [cx, cy] = polygon_operation('getcenter', poly);
        
        varargout{1} = polygon_operation('pack', (x - cx) + ox, ...
            (y - cy) + oy);
        
    case 'plot'
        narginchk(2, 500);
        nargoutchk(0, 0);
        
        [x, y] = polygon_operation('deal', varargin{1});
        plotarg = varargin(2:end);
        
        plotc(x, y, plotarg{:});
        
    case 'convert'
        narginchk(2, 2);
        nargoutchk(1, 1);
        
        in = varargin{1}(:)';
        
        if (mod(numel(in), 2) == 0 && numel(in) > 5)
            varargout{1} = in;
        elseif numel(in) == 4
            
            rectangle = in;
            points = [rectangle(1:2); rectangle(1), rectangle(2) + rectangle(4); ...
                rectangle(1:2) + rectangle(3:4); rectangle(1) + rectangle(3), rectangle(2)];
            
            varargout{1} = polygon_operation('pack', points(:, 1), points(:, 2));
            
        else
            
            error('Unknown format');
        end
        
    case 'interpolate'
        narginchk(2, 3);
        nargoutchk(1, 1);
        
        poly1 = varargin{1};
        poly2 = varargin{2};
        
        if nargin > 3
            factor = varargin{3};
        else
            factor = 0.5;
        end
        
        
    otherwise
        error('Unknown operation');
        
end