function [timer] = timer_create()

timer = struct('current', cputime(), 'laps', []);

