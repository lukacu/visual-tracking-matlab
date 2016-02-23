function [overlap] = polyoverlap(x1, y1, x2, y2)

    [xi, yi] = polybool('intersection', x1, y1, x2, y2);

    A1 = polyarea(x1, y1);
    A2 = polyarea(x2, y2);
    Ai = polyarea(xi, yi);
    
    overlap = Ai / (A1 + A2 - Ai);
    