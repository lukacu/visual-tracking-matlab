function [mask] = segmentation_process_mask(probability, delta)

umask = uint8(255 - 255 * probability ./ (max(probability(:))));

R = mser(umask, delta);

mask = false(size(umask));

for i = R'
    members = erfill(umask, double(i)); 
    mask(members) = true;
end

