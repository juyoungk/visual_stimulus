% directory for movie mat files.
str = computer;
switch str
    case 'MACI64'
        moviedir = '/Users/peterfish/Movies/';
    case 'PCWIN64'
        moviedir = 'C:\Users\Administrator\Documents\MATLAB\database\Movies';
    otherwise
        error('OS should be Mac OS X or PCWIN64');
end

%movext   = '*.mat';
movext   = '*intensity.mat';
%movies = getMovFiles(moviedir, movext);

% movie from files
files = dir(fullfile(moviedir, movext));
nummovies = length(files);
if nummovies < 1
  error('no movies (mat files) in designated folder');
else 
    for fileidx = 1:nummovies
        disp([num2str(fileidx), ': ', files(fileidx).name]); 
    end
end

% cell array for movies
movies = cell(nummovies, 1);
% load movie files
for fileidx = 1:nummovies
    movies(fileidx) = struct2cell(load(fullfile(moviedir, files(fileidx).name)));
end