function [points] = sample_probability_map(M, N)

    if (nargin == 1)
        N = 1;
    end;

    M = normalize(M);

    cols = cumsum(sum(M));
    
    if (all(cols == 0))
        points = [];
        return;
    end;
    
    rv = rand(N, 1);
    
    points = zeros(N, 2);
    
    for i = 1:N;
        mm=cols - rv(i);
        mm(mm < 0) = 2;
        [minv x] = min(mm);

        rows = cumsum(normalize(M(:, x)));

        rvr = rand(1);

        mm=rows - rvr;
        mm(mm < 0) = 2;
        [minv y] = min(mm);
        points(i, :) = [y x];
    
    end;
