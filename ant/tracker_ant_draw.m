function tracker_ant_draw(state)

    parts_draw(state.parts, 1 / state.scaling, 'coloring', 'groups');

    if isfield(state, 'region')
        points = rect2points(state.bounding_box);
        plotc(points(:, 1) ./ state.scaling, points(:, 2) ./ state.scaling, 'LineWidth', 2, 'Color', c('blue'));
    end;
         
    if isfield(state, 'parts_candidate') && ~isempty(state.parts_candidate)
        points = rect2points(state.parts_candidate);
        plotc(points(:, 1) ./ state.scaling, points(:, 2) ./ state.scaling, 'LineWidth', 2, 'Color', c('green'));
    end;
    
    if isfield(state, 'template_candidate') && ~isempty(state.template_candidate)
        points = rect2points(state.template_candidate);
        plotc(points(:, 1) ./ state.scaling, points(:, 2) ./ state.scaling, 'LineWidth', 2, 'Color', c('violet'));
    end;
    
    if isfield(state, 'status_message')
        text(10, 10, state.status_message, 'Color', c('white'), 'BackgroundColor', c('black'));
    end;


    ks = state.kalman_state ./ state.scaling;
    
    plot(ks(1), ks(2), 'wo', 'LineWidth', 3);
    plot([ks(1), ks(1) + ks(3)], [ks(2), ks(2) + ks(4)], ...
        'w', 'LineWidth', 3);
    
    if ~isempty(state.parameters.visualize.template_state)

        memory_draw(state.memory, state.parameters.visualize.template_state);

    end;

    if ~isempty(state.parameters.visualize.candidates_state)

        memory_draw(state.candidates, state.parameters.visualize.candidates_state);

    end;
