function [overlap] = calculate_overlap(T1, T2)
len1 = size(T1, 1);
len2 = size(T2, 1);

if len1 ~= len2
   if len1 == 1
      T1 = repmat(T1, len2, 1);
   end
   if len2 == 1
      T2 = repmat(T2, len1, 1);
   end    
end

hrzInt = min(T1(:, 1) + T1(:, 3), T2(:, 1) + T2(:, 3)) - max(T1(:, 1), T2(:, 1));
hrzInt = max(0,hrzInt);
vrtInt = min(T1(:, 2) + T1(:, 4), T2(:, 2) + T2(:, 4)) - max(T1(:, 2), T2(:, 2));
vrtInt = max(0,vrtInt);
intersection = hrzInt .* vrtInt;

union = (T1(:, 3) .* T1(:, 4)) + (T2(:, 3) .* T2(:, 4)) - intersection;

overlap = intersection ./ union;