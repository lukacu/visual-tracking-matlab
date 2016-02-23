function parts_draw(parts, scaling, varargin)

    trajectories = false;
    dots = false;
    coloring = @coloring_groups;
    thickness = 2;
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'trajectories'
                trajectories = varargin{i+1};
            case 'thickness'
                thickness = varargin{i+1};
            case 'dots'
                dots = varargin{i+1};  
            case 'coloring'
                if ischar(varargin{i+1})
                    switch lower( varargin{i+1})
                    	case 'groups'
                            coloring = @coloring_groups;
                        case 'importance'
                            coloring = @coloring_importance;
                        case 'importance_age'
                            coloring = @coloring_importance_age;
                        otherwise
                            coloring = str2func(varargin{i+1});
                    end
                else
                    if isnumeric(varargin{i+1})
                        coloring = @(x) repmat(varargin{i+1}(:)', parts_size(x), 1);
                    else
                        coloring = varargin{i+1};
                    end;
                end
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end

    colors = coloring(parts);

	count = size(parts.positions, 1);

    p = parts.positions .* scaling;
	s = parts.sizes .* scaling / 2;
    
    if ~isfield(parts.properties, 'region') || ~isfield(parts.properties, 'offset')
        regions = false;
    end

    for i = 1:count
        
        if trajectories
            T = parts.trajectories{i};
            line(T(:, 1) .* scaling, T(:, 2) .* scaling, 'Color', colors(i, :), 'LineWidth', 1); 
            
        end
        
        if ~dots
            points = [p(i, 1) - s(i, 1), p(i, 1) + s(i, 1), p(i, 1) + s(i, 1), p(i, 1) - s(i, 1), p(i, 1) - s(i, 1); ...
                     p(i, 2) - s(i, 2), p(i, 2) - s(i, 2), p(i, 2) + s(i, 2), p(i, 2) + s(i, 2), p(i, 2) - s(i, 2)];

            line(points(1,:), points(2,:), 'Color', colors(i, :), 'LineWidth', thickness);
        else
            plot(p(i, 1), p(i, 2), 'x', 'Color', colors(i, :), 'MarkerSize', thickness);
        end;
                
        if ~isempty(parts.text{i})
           text(p(i, 1), p(i, 2), parts.text{i}, 'Color', colors(i, :));
        end

    end;

end

function [colors] = coloring_groups(parts)

    colors = zeros(parts_size(parts), 3);

    colors(parts.group < 0, 2) = 0.5; 
    colors(parts.group > 0, 1) = 0.7; 
    colors(parts.group == 0, 1) = 0.7; 
    
end

function [colors] = coloring_importance(parts)

    colors = zeros(parts_size(parts), 3);

    colors(:, 1) = parts.importance; 

end

function [colors] = coloring_importance_age(parts)

    colors = zeros(parts_size(parts), 3);

    colors(:, 1) = parts.importance; 

    age = cellfun(@(x) size(x, 1), parts.trajectories, 'UniformOutput', true);
    
    colors(age < 2, 2) = 1;
    
end
