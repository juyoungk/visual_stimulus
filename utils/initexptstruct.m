function ex = initexptstruct(debug)
%
% FUNCTION ex = initexptstruct()
%
% Initialize a structure to hold all experimental information
%
% (c) bnaecker@stanford.edu 2014 
% 22 Jan 2014 - wrote it

% experiment fields
ex = struct('stim', {[]}, 'disp', {[]}, 'key', {[]}, 'me', {[]});

% store the date
ex.today = datestr(now, 'yy-mm-dd');

% time
ex.t_start = datestr(now, 'HH:MM:SS');
ex.t1 = clock;

% debug state
ex.debug = debug;
