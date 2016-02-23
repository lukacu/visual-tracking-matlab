function parts = parts_create(type)

switch(type)
case 'hist8'
    bins = 8;
case 'hist16'
    bins = 16;
case 'hist32'
    bins = 32;
case 'ssd'
    bins = 0;
case 'ncc'
    bins = -2;
end

parts = struct('bins', bins, 'positions', [], ...
		'sizes', [], 'importance', [], ...
		'counter', 0, 'group', []);

parts.data = {};
parts.trajectories = {};
parts.text = {};
parts.properties = struct([]);

