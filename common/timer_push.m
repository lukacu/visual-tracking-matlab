function [timer] = timer_push(timer)

timer.laps(end+1) = cputime() - timer.current;
timer.current = cputime();
