function [I] = immask(I, M)

if (size(I, 3) == 3)
    R = I(:,:,1);
    G = I(:,:,2);
    B = I(:,:,3);

    R(~M) = 0;
    G(~M) = 0;
    B(~M) = 0;

    I = cat(3, R, G, B);
else
    I(~M) = 0;
end;