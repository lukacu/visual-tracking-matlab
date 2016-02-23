function [parts] = parts_push(parts)

    if isempty(parts.trajectories)
        return;
    end;

    parts.trajectories = cellfun(@(t, p) cat(1, t, p), parts.trajectories, num2cell(parts.positions, 2), 'UniformOutput', false);

end