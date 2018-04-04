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
ex.start = datestr(now, 'HH:MM:SS');

% debug state
ex.debug = debug;
