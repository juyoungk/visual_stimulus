%% Load movie files in Workspace
%moviedir = '../database/matfiles/fish_2xds/';
%moviedir = '/Users/peterfish/Movies/';
moviedir = 'C:\Users\Administrator\Documents\MATLAB\database\Movies';
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
%% Digital output??
Deviceindex = PsychHID('Devices')
port = 1 % or 0 (port A)
data = 255;
err=DaqDOut(DeviceIndex, port, data);

%% gammaTable for DLP
% ScreenNum = 0;
% [gammaTable0, dacbits, reallutsize] =Screen('ReadNormalizedGammaTable', ScreenNum);
% %gammaTable0(:,2) = gammaTable0(:,2)*0.6;
% gammaTable0(:,3) = gammaTable0(:,3)*0.5;
% Screen('LoadNormalizedGammaTable', ScreenNum, gammaTable0);
% (0410)
% % Screen('ColorRange') for color range independent of system [0 t1]
% calibration between LEDs: UV is ~12% brighter than Blue at 255 value.
% Blue is brighter by ~25% in middle range color values.

%% Commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')
addpath('utils/')
addpath('jsonlab/')
% screen initialization -> bg color and pd setting
% offset location? % Modify screen.rect by OffsetRect(oldRect,x,y) @ InitScreen
% basedir = fullfile('logs/', ex.today);

%% Test screen (increasing disc?)
testscreen_colors;
%testscreen_annulus;

%% 0716 2018 typing stimulus (generalized checker stimulus) ~ 22 min
ex_title = 'typing';
 n_repeats = 10;
  hp_flash = 1.5; % secs
hp_grating = 1.5;
hp_speed = 1.5;
sizeCenter = 0.6;
% ndims=[1,1]: flash mode. Impulse turn on and off.
flash = struct('tag', 'flash', 'ndims', [1,1], 'sizeCenter', sizeCenter, 'half_period', hp_flash);
annul = struct('tag', { 'Ann1.2', 'Ann1.6'}, 'ndims', [1,1], 'sizeCenter', 0,...
               'Annulus', {1.2,  1.6},...
                        'w_Annulus', .4, 'half_period', hp_flash);
% moving annulus? 'Annulus', [1., 2.5]                   
% Nonlinear spatial summation: RF or Dendritic field size of the bipolar cells ~ 23 um (W3 paper)
% 14 bars / 640 um ~ width: 50 um
grating = struct('tag', 'grating',...
                'ndims', {[28,1], [14,1]},...% center size is redefined by the integer times grating?
                'sizeCenter', sizeCenter, 'half_period', hp_grating,...
                'cycle', 3,... 
                'phase_1st_cycle', 1);
% bg texture input: long range > 1 mm input can exist?
bgtex = struct('tag', {'bgtex','global','diff'}, 'half_period', hp_grating,...
                'ndims', [14,1], 'sizeCenter', sizeCenter, 'BG', 1.6,...
                'draw_center', {false,  true,   true},...% {B , C+B, C+B}
                      'cycle', {    3,     2,      2},... 
            'phase_1st_cycle', {    1,    [],     []},...
                      'delay', {    0,     0,   0.25});  % {global, global, diff}
% Speed tuning: population picture of amacrine cells
% frame rate
speed = struct('tag', 'speed', 'half_period', hp_speed,...
                'ndims', [7,1], 'sizeCenter', sizeCenter,...%'BG', 1.6,... 
                'phase_1st_cycle', { 1, [], [], []},...
                          'cycle', { 2,  1,  1,  1},... 
                'shift_per_frame', {.25, .50, 1., 2.}); % in px.(~ speed). 1 px * 21um * 60 Hz = 1260 um/s
%            
blank = struct('tag', ' ', 'ndims', [1,1], 'color', [0 0 0], 'sizeCenter', 0.0, 'half_period', hp_flash); 
%
stim = [];
%stim = addStruct(stim, flash);
%stim = addStruct(stim, annul);
%stim = addStruct(stim, grating);
%stim = addStruct(stim, bgtex);
stim = addStruct(stim, speed);
stim = addStruct(stim, blank);
%
ex = stims_repeat(stim, n_repeats, 'title', ex_title, 'debug', 1, 'mode', '');

%% 1D moving texture
ex_title = 'mov_1d_bar_tex';
debug_exp = false;
params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'repeat', 1, 'length', 3,... % mins 
                    'mov_id',   {1, 3},... 
                'startframe', {910, 450}, 'seed', 7,...
                'ndims', [1, 110], 'scale', 0.5, 'jitter_var', 0.5,...
                'c_mask', [0, 1, 1]); 
% script for playing stimulus. 'params' & 'ex_title' should be defined in advance.
run_stims


%% Repeat natural movies: Cell's reproducibility to natural movies? (1 min)
% combination of multiple 'movies' (cell array in worksapce).
% cell array in values -> struct array
ex_title = 'Nat_movies_short_repeats';
debug_exp = false;
params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'length', 0.3, 'repeat', 1,... 
                    'mov_id',   {1, 3},... 
                'startframe', {910, 450}, 'seed', 7,... 
                'ndims', [128, 128], 'scale', 0.5, 'jitter_var', 0.5, 'c_mask', [0, 1, 1]); 
% 1 stim px bar ~ um?             
% script for playing stimulus. 'params' & 'ex_title' should be defined in advance.
run_stims

%% Main recording: Natural movie. Synchronized inhibition during natural movies? 
% 1.4 mm aperture : 2.7 mm [64 64] mov, 35 grid checkers  1.48 mm
% 1.3 mm apergure : 1.36 mm [64 64] mov
ex_title = 'Nat_movies_10mins';
debug_exp = false;
nm_params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'length', 10, 'repeat', 1,... 
                'mov_id', [1, 2, 3, 4], 'startframe', 1, 'seed', 7,... 
                'ndims', [128, 128], 'scale', 0.5, 'jitter_var', 0.5, 'c_mask', [0, 1, 1]); % mask is mask for alpha blending. 
                % nimds: subimage sampling dimension. 
                % Presentation dim = ndims * scale.
                % dst rect (or aperture) size = m (integer) * Presentation dim.
params= nm_params;
%
run_stims

%% Typing by Full-field noise stim: aligned depol & hypol events & adaptation/sensitization: Functional classification
% Not for RF since it cannot replay. Binary noise would be sufficient. 
    % contrast = STD/mean. 0.35 to 0.05 for Baccus and Meister 2002 
i = 1; % ex or FOV id
j = 1;
 duration = 12;
n_repeats = 5;
framerate = 20;
stim_noise    = struct('ndims', [1, 1, 3], 'sizeCenter', 0.6, 'noise_contrast',   1, 'color', [0  1  1], 'half_period', duration/2., 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
stim_noise(j) = struct('ndims', [1, 1, 3], 'sizeCenter', 0.6, 'noise_contrast', 0.2, 'color', [0  1  1], 'half_period', duration/2., 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
ex_ff_noise = stims_repeat(stim_noise, n_repeats, 'framerate', framerate, 'debug', true);

%% Moving Bar: Probing Wide-field effect.
% A bar of width 160 mm (2.4º) moving at 500 mm per s (7.5º per s). Johnston and Lagnado (2016)
% Stim size: 128 px ~ 2600 um
n_repeats = 10;
moving_bar('barColor', 'dark','c_mask', [0 1 1], 'barWidth', 150, 'barSpeed', 1.4, 'angle_every', 45, 'N_repeat', 8 * n_repeats); 
%%
moving_bar('barColor','white','c_mask', [0 1 1], 'barWidth', 150, 'barSpeed', 1.4, 'angle_every', 45, 'N_repeat', 8 * n_repeats);

%% Full-fild WN (Gaussian): Linear vs Nonlinear populations
ex_title = 'Uniform_Whitenoise_UV';
debug_exp = false;
% Full-field (2 mean level) Gaussian Whitenoise [5 min each]: temporal filter change?
wn_params = struct('function', 'whitenoise', 'framerate', 20, 'seed', 0,... 
                'ndims', [1,1], 'dist', 'gaussian', 'contrast', 0.35,... 
                'length', 5, 'w_mean', {1.0, 0.2}, 'c_mask', [0, 1, 0]); k = length(wn_params);
params = wn_params;
%
run_stims

%% Bar (color) whitenoise across the dorsal-ventral direction            
ex_title = 'Bar_1d_wn_Color';
wn_params = struct('function', 'whitenoise', 'framerate', 20, 'seed', 0,... 
                'ndims', [35,1,3], 'dist', 'binary', 'contrast', 1,... 
                'length', 10, 'w_mean', 1, 'c_mask', [0, 1, 1]); 
%            
%params = addStruct(nm_params, wn_params)
params = wn_params;
%
run_stims


%%
replay % for runjuyoung


%% Whitenoise and natural movie stimulus
% intensity factor = 0.7 @ initdisp (0306 2018)
runjuyoung;

%% Repeat natural movies (color, 256): Cell's reproducibility to natural movies? (1 min)
% combination of multiple movies.
params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'length', 0.2, 'repeat', 3,... 
                'mov_id', {1, 2}, 'startframe', {600, 200}, 'seed', 7,... 
                'ndims', [256,256,3], 'scale', 0.5, 'jitter_var', 0.5, 'c_mask', [0, 1, 1]);
%             
% params(2) = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
%                 'length', 0.2, 'repeat', 3,... 
%                 'mov_id', 2, 'startframe', 200, 'seed', 7,... 
%                 'ndims', [256,256,3], 'scale', 0.5, 'jitter_var', 0.5, 'c_mask', [0, 1, 1]);
%ex = run_naturalmovie(movies, params); % mov = 4-D matrix
% script for playing stimulus. 'params' should be defined in advance.
run_stims

%% Global/Differential motion to compute avg motion feature (UV or Blue)
% Normally distributed jitter sequence. (default variance = 0.5) 
% press 'q' to jump to next session. Not Arrows (rotation)
OMS_jitter_color_mask('seed', 1, 'sDuration', 15, 'N_repeats', 5, 'random_repeat', true, 'color_Mask', [0 1 0], 'c_intensity', 0.7); % 2.5 min (sDuration x 2 x N_repeats)
%%
OMS_jitter_color_mask('seed', 1, 'sDuration', 15, 'N_repeats', 5, 'random_repeat', true, 'color_Mask', [0 1 0], 'background', false, 'c_intensity', 0.7); % 2.5 min (sDuration x 2 x N_repeats)
%OMS_jitter_color_mask('seed', 1, 'sDuration', 10, 'N_repeats', 20, 'random_repeat', true, 'color_Mask', [0 1 1], 'sync_to_ch', 2); % 10 min (sDuration x 2 x N_repeats)

%% Replay the stim as movie
% [rows, cols, 3, frames]
stim_mov = h5read('stimulus.h5', '/expt3/stim');
m = immovie(stim_mov);
movie(m);

%%
% 10x objective lens for stim?? and calibration

                
%% identification OMS g-cells and PA a-cells?
% differential step stimulus
% Bar width = 100 um
%OMS_diff_Grating_Phase_Scan; % Arrow? next session (e.g. phase)
                             % Esc throws an error.
%%                             


