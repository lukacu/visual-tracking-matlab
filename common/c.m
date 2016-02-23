function [color] = c(name)

if (ischar(name))
    switch (lower(name))
        case 'red'
            id = 0;
        case 'green'
            id = 1;
        case 'blue'
            id = 2;
        case 'black'
            id = 3;
        case 'brown'
            id = 4;            
        case 'yellow'
            id = 5;
        case 'gray'
            id = 6;
        case 'violet'
            id = 7;
        case 'orange'
            id = 8;
        case 'aqua'
            id = 9;
        case 'lightgray'
            id = 10;
        case 'white'
            id = 11;
    end
else
    id = int32(name);
end

switch (id)
    case 0
        color = [1, 0, 0];
    case 1
        color = [0, 1, 0];
    case 2
        color = [0, 0, 1];
    case 3
        color = [0, 0, 0];
    case 4
        color = [86, 33, 14] / 255;
    case 5
        color = [1, 1, 0];
    case 6
        color = [0.5, 0.5, 0.5];
    case 7
        color = [0.5, 0, 1];
    case 8
        color = [1, 0.5, 0];
    case 9
        color = [0, 1, 1];
    case 10
        color = [0.75, 0.75, 0.75];
    case 11
        color = [1, 1, 1];        
end

        
        
        
        
        
        
        
        
        