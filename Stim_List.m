%% Commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')
addpath('utils/')
addpath('jsonlab/')
% screen initialization -> bg color and pd setting
% offset location? % Modify screen.rect by OffsetRect(oldRect,x,y) @ InitScreen
% basedir = fullfile('logs/', ex.today);

%% Load movie files in Workspace
load_mat_movie_files;

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

%% Test screen (increasing disc?)
testscreen_colors;
%testscreen_annulus;

%% Gray (flash phase 0.5) with early (30s) and late (300s) flash repeats: Reliability/Clustering
ex_title = 'flash';
sizeCenter = 0.8;
%
flash_duration = 3; % sec1
flash_cycles   = 10;  % number of repeats
% gray adapting screen durations
short_adapting = 10; %30;
long_adapting = 240;
%
gray_short = struct('tag', 'start screen', 'ndims', [1,1], 'sizeCenter', sizeCenter, 'half_period', short_adapting/2., 'phase_1st_cycle', 0.5);
gray_long  = struct('tag', 'start screen', 'ndims', [1,1], 'sizeCenter', sizeCenter, 'half_period', long_adapting/2., 'phase_1st_cycle', 0.5);
%
white_screen = struct('tag', 'start screen', 'ndims', [1,1], 'sizeCenter', sizeCenter, 'half_period', flash_duration/2., 'phase_1st_cycle', 1);
flash = struct('tag', 'flash', 'ndims', [1,1], 'cycle', flash_cycles, 'sizeCenter', sizeCenter, 'half_period', flash_duration);
%
stim = [];
% 1st flash
stim = addStruct(stim, gray_short);
stim = addStruct(stim, white_screen); % half period
stim = addStruct(stim, flash);
% 2nd flash
%stim = addStruct(stim, gray_long);
%stim = addStruct(stim, white_screen);
%stim = addStruct(stim, flash);
%
n_repeats = 1;
ex = stims_repeat(stim, n_repeats, 'title', ex_title, 'debug', 0, 'mode', '');

%% WN (Gaussian):
% contrast = STD/mean. 0.35 to 0.05 for Baccus and Meister 2002 
% mean change --> temporal filter change?
ex_title = 'GaussianCheckers';
debug_exp = 0;
gr_duration = 3; % secs
wn_long = 10; % min
% 2 contrast levels
h_contrast = 0.35;
contrast = {h_contrast};
duration = { wn_long}; % total 1.5 + 5 min.
%
gr_screen = struct('function', 'grayscreen', 'length', gr_duration, 'c_mask', [0, 1, 1], 'ndims', 50); % aperturesize gray screen
wn_params = struct('function', 'whitenoise', 'framerate', 20, 'seed', 0,... % PD trigger: every framerate(20) ~ 1s
                'ndims', [35,35,3], 'dist', 'gaussian', 'contrast', contrast,...
                'length', duration, 'w_mean', 1, 'c_mask', [0, 1, 1]); 
params = addStruct(gr_screen, wn_params);
%params = wn_params;
%
run_stims

%% Full-fild WN (Gaussian): Linear vs Nonlinear populations, Adapting vs non-adapting populations
% contrast = STD/mean. 0.35 to 0.05 for Baccus and Meister 2002 
% mean change --> temporal filter change?
ex_title = 'FullField_WhiteNoise';
debug_exp = 0;
gr_duration = 180; % secs
wn_duration = 15/60. % min
wn_long = 5; % min
% 2 contrast levels
h_contrast = 0.35;
l_contrast = 0.05;
contrast = { l_contrast,  h_contrast,  l_contrast,  h_contrast,  l_contrast,  h_contrast,  l_contrast, h_contrast};
duration = {wn_duration, wn_duration, wn_duration, wn_duration, wn_duration, wn_duration, wn_duration,    wn_long}; % total 1.5 + 5 min.
%seed = {
%
gr_screen = struct('function', 'grayscreen', 'length', gr_duration, 'c_mask', [0, 1, 1], 'ndims', 50); % aperturesize gray screen
wn_params = struct('function', 'whitenoise', 'framerate', 20, 'seed', 0,... % PD trigger: every framerate(20) ~ 1s
                'ndims', [1,1], 'dist', 'gaussian', 'contrast', contrast,...
                'length', duration, 'w_mean', 1, 'c_mask', [0, 1, 1]); 
params = addStruct(gr_screen, wn_params);
%params = wn_params;
%
run_stims

%% 1D naturalistic texture (single trial long movie): 1D model using natural scenes
% ndims is a presentation size. [50, 1] for 1D.
ex_title = 'natmov_1d_tex';
debug_exp = 0;
%
gr_duration = 240; % secs. 
gr_screen = struct('function', 'grayscreen', 'length', gr_duration, 'c_mask', [0, 1, 1], 'ndims', 50); % aperturesize gray screen
params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'repeat', 1, 'length', 5,...% mins. max duration for each movie.  
                'mov_id', {3,1,3,4,1,4,1},... 
                  'seed', {3,3,4,1,4,8,8}, 'startframe', 200,...  % different seed number?
                 'ndims', [50, 1], 'jitter', 0.5, 'sampling_scale', 2,... % 'ndims' & 'jitter' in presentation (stimulus) domain.
                'c_mask', [0, 1, 1]);
params = addStruct(gr_screen, params);
% script for playing stimulus. 'params' & 'ex_title' should be defined in advance.
run_stims

%% Nat mov vs whitenoise. 2D.
% mov1 - honet
% mov2 - Birds
% mov3 - Falcon
% mov4 - Mudskipper
ex_title = 'nat_vs_wn_2d';
debug_exp = 0;
%
gr_duration = 240; % secs
wn_duration = 3; % min. fixed.
na_duration = 5; % min. max for each movie.

% sequence = {'whitenoise', 'naturalmovie2', 'whitenoise', 'naturalmovie2', 'whitenoise', 'naturalmovie2'};
% duration = {wn_duration,      na_duration,  wn_duration,     na_duration,  wn_duration,   na_duration*2};
% mov_ids =  {          0,            [3,1],            0,            [4,3],           0,         [1,4,3]};
% seeds =    {          0,                3,            1,                8,           2,              4};

sequence = {'whitenoise', 'naturalmovie2', 'whitenoise', 'naturalmovie2'};
duration = {wn_duration,      na_duration,  wn_duration,     na_duration};
mov_ids =  {          0,            [3,1],            0,            [4,3]};
seeds =    {          0,                3,            1,                8};

gr_screen = struct('function', 'grayscreen', 'length', gr_duration, 'c_mask', [0, 1, 1], 'ndims', 50); % aperturesize gray screen
params = struct('function', sequence, 'framerate', 30, 'jumpevery', 60,... 
                'repeat', 1, 'length', duration,...% mins. max duration for each movie.  
                'mov_id', mov_ids, 'startframe', 200, 'jitter', 0.5, 'sampling_scale', 2,... % 'ndims' & 'jitter' in presentation (stimulus) domain.
                  'seed', seeds,... 
                  'dist', 'gaussian', 'contrast', 0.35,...
                 'ndims', [50, 50], ... 
                'c_mask', [0, 1, 1]); 
params = addStruct(gr_screen, params);
% script for playing stimulus. 'params' & 'ex_title' should be defined in advance.
run_stims

%% Natural movies (single trial long movie): 2D model using natural scenes.
% ndims is a presentation size. [50, 1] for 1D.
ex_title = 'natmov';
debug_exp = 0; 
%
gr_duration = 240; % secs
gr_screen = struct('function', 'grayscreen', 'length', gr_duration, 'c_mask', [0, 1, 1]); % aperturesize gray screen
params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'repeat', 1, 'length', 5,...% mins. max duration for each movie.  
                'mov_id', {3,3,3,4,1,4,1},... 
                  'seed', {3,3,4,1,4,8,8}, 'startframe', 200,...  % different seed number?
                 'ndims', [50, 50], 'jitter', 0.5, 'sampling_scale', 2,... % 'ndims' & 'jitter' in presentation (stimulus) domain.
                'c_mask', [0, 1, 1]); 
params = addStruct(gr_screen, params);
% script for playing stimulus. 'params' & 'ex_title' should be defined in advance.
run_stims

%%
replay

%% Speed tuning: 600 um aperture (or 2400 um?)
ex_title = 'speed';
 n_repeats = 5;
hp_speed = 3.;
sizeCenter = 0.6;
ex_title = [ex_title, num2str(sizeCenter)];
%
gr_duration = 180;
gray_screen = struct('tag', 'start screen', 'ndims', [1,1], 'sizeCenter', sizeCenter, 'half_period', gr_duration/2., 'phase_1st_cycle', 0.5);
start = struct('tag', 'start screen', 'half_period', hp_speed/2.,...
                'ndims', [10,1], 'sizeCenter', sizeCenter,...%'BG', 1.6,... 
                'phase_1st_cycle', 0,... % shift_max is curreently 2.
                          'cycle', 1);

speed = struct('tag', 'speed', 'half_period', hp_speed,...
                'ndims', [10,1], 'sizeCenter', sizeCenter,...%'BG', 1.6,... 
                'phase_1st_cycle', [],...
                          'cycle', 1,...
                      'shift_max', {  6,  12,  18, 24,  36,  48},... % in phase. 1.6s transition
                'shift_per_frame', {.25, .50, .75,  1., 1.5, 2});    % in px.(~ speed). 1 px * 21um * 60 Hz = 1260 um/s.

%
stim = [];
stim = addStruct(stim, gray_screen);
stim = addStruct(stim, start);
stim = addStruct(stim, speed);
%
ex = stims_repeat(stim, n_repeats, 'title', ex_title, 'debug', 0, 'mode', '');

%% Step motion stimulus 
ex_title = 'tex steps';
 n_repeats = 8;
hp_grating = 2.5;
sizeCenter = .6;
%
start = struct('tag', 'start screen', 'half_period', hp_grating,...
                'ndims', [14,1], 'sizeCenter', sizeCenter, 'BG', 1.6,...
                'draw_center', false, 'phase_1st_cycle', 1); % shift_max is curreently 2.
                          
bgtex = struct('tag', {'bgtex','global','diff'}, 'half_period', hp_grating,...
                'ndims', [14,1], 'sizeCenter', sizeCenter, 'BG', 1.6,...
                'draw_center', {false,  true,   true},...% {B , C+B, C+B}
                      'cycle', 2,... 
                      'delay', {    0,     0,   0.25});  % {global, global, diff}
% bg texture input: long range > 1 mm input can exist?
% [row col] convension. [14, 1] is along up-down direction (Dorsal-Ventral)
%
stim = [];
stim = addStruct(stim, start);
stim = addStruct(stim, bgtex);
%
ex = stims_repeat(stim, n_repeats, 'title', ex_title, 'debug', 0, 'mode', '');

%% Reliability: 1D moving texture (5 repeats): only for 24s
% 'ndims': presentation (stimulus) space
% 'jitter': variance of jitter in presentation space.
ex_title = 'natmov_1d_tex_mov3_5reps';
debug_exp = 0; % debug mode 2: space-time visualization (not replay)
params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'repeat', 5, 'length', 0.4,...    % mins. for each movie.  
                    'mov_id', {3},... 
                'seed', 3, 'startframe', 400,... 
                'ndims', [50 , 1], 'jitter', 0.5, 'sampling_scale', 2,... % 'ndims' & 'jitter' in presentation (stimulus) domain.
                'c_mask', [0, 1, 1]);
% script for playing stimulus. 'params' & 'ex_title' should be defined in advance.
                % nimds: presenntation dimension. 
                % subimage sampling dim = ndims * scale.
                % dst rect (or aperture) size = m (integer) * Presentation dim.
run_stims




%% Typing stimulus (generalized checker stimulus)
ex_title = 'typing';
 n_repeats = 5;
  flash_duration = 2; % secs
hp_grating = 2;
sizeCenter = 0.6;

% ndims=[1,1]: flash mode. Impulse turn on and off.
flash = struct('tag', 'flash pulse', 'ndims', [1,1], 'sizeCenter', sizeCenter, 'half_period', flash_duration);
annul = struct('tag', { 'Ann1.2', 'Ann1.6'}, 'ndims', [1,1], 'sizeCenter', 0,...
               'Annulus', {1.2,  1.6},...
                        'w_Annulus', .4, 'half_period', flash_duration);
% moving annulus? 'Annulus', [1., 2.5]                   
% Nonlinear spatial summation: RF or Dendritic field size of the bipolar cells ~ 23 um (W3 paper)
% 14 bars / 640 um ~ width: 50 um
grating = struct('tag', 'grating',...
                'ndims', {[28,1], [14,1]},...% center size is redefined by the integer times grating?
                'sizeCenter', sizeCenter, 'half_period', hp_grating,...
                'cycle', 3,... 
                'phase_1st_cycle', 1);
% bg texture input: long range > 1 mm input can exist?
% [row col] convension. [14, 1] is along up-down direction (Dorsal-Ventral)
bgtex = struct('tag', {'bgtex','global','diff'}, 'half_period', hp_grating,...
                'ndims', [14,1], 'sizeCenter', sizeCenter, 'BG', 1.6,...
                'draw_center', {false,  true,   true},...% {B , C+B, C+B}
                      'cycle', {    3,     2,      2},... 
            'phase_1st_cycle', {    1,    [],     []},...
                      'delay', {    0,     0,   0.25});  % {global, global, diff}
%            
blank = struct('tag', ' ', 'ndims', [1,1], 'color', [0 0 0], 'sizeCenter', 0.0, 'half_period', flash_duration); 
%
stim = [];
%stim = addStruct(stim, flash);
%stim = addStruct(stim, annul);
%stim = addStruct(stim, grating);
stim = addStruct(stim, bgtex);
stim = addStruct(stim, blank);
%
ex = stims_repeat(stim, n_repeats, 'title', ex_title, 'debug', 0, 'mode', '');


%% Repeat natural movies: Cell's reproducibility to natural movies? (1 min)
% combination of multiple 'movies' (cell array in worksapce).
% cell array in values -> struct array
ex_title = 'Nat_movies_short_repeats';
debug_exp = false;
params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'length', 0.3, 'repeat', 3,... 
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
ex_ff_noise = stims_repeat(stim_noise, n_repeats, 'framerate', framerate, 'debug', 0);

%% Moving Bar: Probing Wide-field effect.
% A bar of width 160 mm (2.4º) moving at 500 mm per s (7.5º per s). Johnston and Lagnado (2016)
% Stim size: 128 px ~ 2600 um
n_repeats = 10;
moving_bar('barColor', 'dark','c_mask', [0 1 1], 'barWidth', 150, 'barSpeed', 1.4, 'angle_every', 45, 'N_repeat', 8 * n_repeats); 
%%
moving_bar('barColor','white','c_mask', [0 1 1], 'barWidth', 150, 'barSpeed', 1.4, 'angle_every', 45, 'N_repeat', 8 * n_repeats);

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
%% Digital output??
Deviceindex = PsychHID('Devices')
port = 1 % or 0 (port A)
data = 255;
err=DaqDOut(DeviceIndex, port, data);


