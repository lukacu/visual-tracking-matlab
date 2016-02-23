function [rectangle] = fit_rectangle(probability, initial, iterations, size_prior, size_influence)

integral = cumsum(cumsum(probability), 2);

[H, W] = size(probability);

x1 = max(2, round(initial(1)));
y1 = max(2, round(initial(2)));

x2 = min(W-1, round(initial(1) + initial(3)));
y2 = min(H-1, round(initial(2) + initial(4)));

%climb = [];

j = 0;

best_rect = [];
best_score = 0;

if nargin < 4
    size_prior = (initial(3) * initial(4)) / 2;
end;

if nargin < 5
    size_influence = 10;
end;

X = [x1, y1, x2, y2];

moves = [1, 0, 0, 0; -1, 0, 0, 0; 0, 1, 0, 0; 0, -1, 0, 0; 0, 0, 1, 0; 0, 0, -1, 0; 0, 0, 0, 1; 0, 0, 0, -1];
%moves = [1, 0, 0, 0; 0, 1, 0, 0; 0, 0, -1, 0; 0, 0, 0, -1];

while j < iterations
    
    n = zeros(1, 8);
    for i = 1:8
        n(i) = calculate_score(probability, integral, X + moves(i, :), size_prior, size_influence);
    end;

    n(isinf(n)) = 0;
    
    [score, i] = max(n);

    %climb(end+1) = score;

    X = X + moves(i, :);
 
    if best_score < score
       best_score = score;
       best_rect = X;
    %else
    %    break;
       
    end
        
    j = j + 1;

    if (X(1) >= X(3)) || (X(2) >= X(4))
        break;
    end
    
end

if ~isempty(best_rect)
    rectangle = [best_rect(1), best_rect(2), best_rect(3) - best_rect(1), best_rect(4) - best_rect(2)];
else
    rectangle = [];    
end;
%rectangle
end

function score = calculate_score(map, int, X, prior, influence)

     if (X(1) < 1 || X(3) >= size(map, 2)) || (X(2) < 1 || X(4) >= size(map, 1))
        score = 0;
        return;
     end

    v = int(X(4), X(3)) - int(X(4), X(1)) - int(X(2), X(3)) + int(X(2), X(1));

    vol = (X(3) - X(1)) * (X(4) - X(2));
    score = v / vol;
    score = score / ((int(end, end) - v) / (numel(map) - vol) + eps);
    
    f = ((vol - prior) * (vol - prior) + 1);
    
    score = score + influence/f;
end

