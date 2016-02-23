function tracker_lgt_draw(state)

    parts_draw(state.parts, 1 / state.scaling, 'coloring', 'importance_age');
    
    positions = state.parts.positions ./ state.scaling;
    
    hull = convhull(positions(:, 1), positions(:, 2));
    plot(positions(hull, 1), positions(hull, 2), 'LineWidth', 2, 'Color', [1 0 0]);
        
    motion = state.kalman_state / state.scaling;
    
    plot([motion(1), motion(1) + motion(3)], [motion(2), motion(2) + motion(4)], 'g', 'LineWidth', 3);
    plot(motion(1), motion(2), 'go', 'LineWidth', 3);
    
    if ~isempty(state.parameters.visualize.modalities_state)

        modalities_draw(state.modalities, state.parameters.visualize.modalities_state);
        
    end;    
    
    
