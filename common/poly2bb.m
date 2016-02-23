function p = poly2bb( x, y )


    xy = [x(:), y(:)];

    % get transformation
    C = cov(xy) ;
    Mu = mean(xy) ;

    xy = bsxfun(@minus, xy, Mu) ;

    [U,~,~] = svd(C) ;

    xy2 = xy*U ;

    minx = min(xy2(:,1)) ; maxx = max(xy2(:,1)) ;
    miny = min(xy2(:,2)) ; maxy = max(xy2(:,2)) ;
    p2 = [minx, miny; maxx, miny; maxx, maxy; minx, maxy] ;
    p = bsxfun(@plus,p2*U',Mu) ;

    x = p(:, 1);
    y = p(:, 2);
    
    e1 = sqrt(sum(([x(1), y(1)] - [x(2), y(2)]) .^ 2));
    e2 = sqrt(sum(([x(3), y(3)] - [x(2), y(2)]) .^ 2));
    
    if e1 > e2
        ratio = e2 / e1;
    else
        ratio = e1 / e2;
    end

    if ratio > 0.85
       
        cx = mean(x);
        cy = mean(y);
        w = (e1 + e2) / 2;

        p = [cx - w / 2, cy - w / 2; cx + w / 2, cy - w / 2; cx + w / 2, cy + w / 2; cx - w / 2, cy + w / 2];
        
    end
        
        