 function w = hann(n,b)

if nargin==1
    b='symmetric';
end

if strcmp(b,'symmetric')
    i = 1:n;
    w(i,1) = 0.5*(1-cos((2*pi*(i-1))/(n-1)));
elseif strcmp(b,'periodic')
    i = 1:n;
    w(i,1) = 0.5*(1-cos((2*pi*(i-1))/(n)));
else
    disp('Error')
end

