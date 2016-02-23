function bounds = parts_bounds(parts, selection)

if nargin == 1
    selection = 1:size(parts.positions, 1);
end;

minx = min(parts.positions(selection, 1) - parts.sizes(selection, 1) / 2);
miny = min(parts.positions(selection, 2) - parts.sizes(selection, 2) / 2);
maxx = max(parts.positions(selection, 1) + parts.sizes(selection, 1) / 2);
maxy = max(parts.positions(selection, 2) + parts.sizes(selection, 2) / 2);

bounds = [minx, miny, maxx - minx, maxy - miny];
    