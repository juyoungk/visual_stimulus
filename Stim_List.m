%% Load movie files in Workspace
%moviedir = '../database/matfiles/fish_2xds/';
moviedir = '/Users/peterfish/Movies/';
%moviedir = 'C:\Users\Administrator\Documents\MATLAB\database\Movies';
movext   = '*.mat';
%movies = getMovFiles(moviedir, movext);

% movie from files
files = dir(fullfile(moviedir, movext));
nummovies = length(files);
if nummovies < 1
  error('no movies (mat files) in designated folder');
end
movies = cell(nummovies, 1);
% laod movie files
for fileidx = 1:nummovies
    movies(fileidx) = struct2cell(load(fullfile(moviedir, files(fileidx).name)));
end
%% Digital output??
Deviceindex = PsychHID('Devices')
port = 1 % or 0 (port A)
data = 255;
err=DaqDOut(DeviceIndex, port, data);

%% gammaTable for DLP
[gammaTable0, dacbits, reallutsize] =Screen('ReadNormalizedGammaTable', 2);
gammaTable0(:,2) = gammaTable0(:,2)*0.6;
%%
Screen('LoadNormalizedGammaTable', 2, gammaTable0);
% Screen('ColorRange') for color range independent of system [0 t1]
%% Commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')
addpath('utils/')
addpath('jsonlab/')
% common parameters for all stimuli
debug = 0;
% screen initialization -> bg color and pd setting
% offset location? % Modify screen.rect by OffsetRect(oldRect,x,y) @ InitScreen
% basedir = fullfile('logs/', ex.today);
i = 1; % ex or FOV id
%% Test screen (increasing disc?)
testscreen_colors;
%testscreen_annulus;

%% Checkerboard style stim definition (Functional typing)
% size in mm, period in secs
% BG mode: 0 - No BG, 1 - Checkers (same pattern as center)
% BG size = aperture size.
% calibration between LEDs: UV is ~12% brighter than Blue at 255 value.
% Blue is brighter by ~25% in middle range color values.
% (0410)
stim = []; j=1;
w = [1 1 1]; % color weight (calibration) factor or mean level
blueUV = [0 .5 .5]; % white color mix ratio
% half period (secs)
     n_repeats = 1;
      hp_flash = 1;
    hp_grating = 1;
stim    = struct('ndims',[1,1], 'sizeCenter', 0.6, 'BG', 0, 'Annulus', 0, 'w_Annulus', .3, 'color', [0  1  0].*w, 'half_period', hp_flash, 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
stim(j) = struct('ndims',[1,1], 'sizeCenter', 0.6, 'BG', 0, 'Annulus', 0, 'w_Annulus', .3, 'color', [0  0  1].*w, 'half_period', hp_flash, 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
stim(j) = struct('ndims',[1,1], 'sizeCenter', 0.6, 'BG', 0, 'Annulus', 0, 'w_Annulus', .3, 'color',    blueUV.*w, 'half_period', hp_flash, 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
% Flickering annulus
stim(j) = struct('ndims',[1,1], 'sizeCenter', 0.6, 'BG', 0, 'Annulus', 1.2,       'w_Annulus', .3, 'color', blueUV.*w, 'half_period', hp_flash, 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
stim(j) = struct('ndims',[1,1], 'sizeCenter', 0.6, 'BG', 0, 'Annulus', 1.6,       'w_Annulus', .3, 'color', blueUV.*w, 'half_period', hp_flash, 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
stim(j) = struct('ndims',[1,1], 'sizeCenter', 0.6, 'BG', 0, 'Annulus', 2.0,       'w_Annulus', .3, 'color', blueUV.*w, 'half_period', hp_flash, 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
% Moving annulus
stim(j) = struct('ndims',[1,1], 'sizeCenter', 0.0, 'BG', 0, 'Annulus', [1., 2.5], 'w_Annulus', .3, 'color', blueUV.*w, 'half_period', hp_flash, 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
stim(j) = struct('ndims',[1,1], 'sizeCenter', 0.0, 'BG', 0, 'Annulus', [2.5, 1.], 'w_Annulus', .3, 'color', blueUV.*w, 'half_period', hp_flash, 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
% % % Nonlinear spatial summation: RF or Dendritic field size of the bipolar cells ~ 23 um (W3 paper)
% stim(j) = struct('ndims',[28, 1], 'sizeCenter', 0.64, 'BG', 0, 'color', blueUV.*w, 'half_period', hp_grating, 'cycle', 2, 'phase', 0, 'delay', 0); j=j+1;
% stim(j) = struct('ndims',[14, 1], 'sizeCenter', 0.64, 'BG', 0, 'color', blueUV.*w, 'half_period', hp_grating, 'cycle', 2, 'phase', 0, 'delay', 0); j=j+1;
% % pause
% stim(j) = struct('ndims',[1, 1], 'sizeCenter', 0.6, 'BG', 0, 'color', [0 0 0].*w, 'half_period', hp_grating/2., 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;

% Global & diff motion: 14 bars / 640 um ~ width: 50 um
stim(j) = struct('ndims',[14, 1], 'sizeCenter', 0.64, 'BG', 1, 'Annulus', 0, 'w_Annulus', .3, 'color', blueUV.*w, 'half_period', hp_grating, 'cycle', 2, 'phase', 0, 'delay', 0); j=j+1;
stim(j) = struct('ndims',[14, 1], 'sizeCenter', 0.64, 'BG', 1, 'Annulus', 0, 'w_Annulus', .3, 'color', blueUV.*w, 'half_period', hp_grating, 'cycle', 2, 'phase', 0, 'delay', 0.25); j=j+1;
%stim(j) = struct('ndims',[1, 12], 'sizeCenter', 0.6, 'BG', 1, 'Annulus', 0, 'w_Annulus', .3, 'color', blueUV.*w, 'half_period', hp_grating, 'cycle', 2, 'phase', 0, 'delay', 0.25); j=j+1;
%
ex_typing = stims_repeat(stim, n_repeats); i = i + 1; % FOV (or ex) index % + options % save the stim in log forder?

%% Full-field noise stim: aligned depol & hypol events & adaptation/sensitization: Functional classification
% Not for RF since it cannot replay. Binary noise would be sufficient. 
    % contrast = STD/mean. 0.35 to 0.05 for Baccus and Meister 2002 
j=1;
 duration = 5;
n_repeats = 3;
framerate = 10;
stim    = struct('ndims', [1, 1, 3], 'sizeCenter', 0.6, 'noise_contrast',   1, 'color', [0  1  1], 'half_period', duration/2., 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
stim(j) = struct('ndims', [1, 1, 3], 'sizeCenter', 0.6, 'noise_contrast', 0.2, 'color', [0  1  1], 'half_period', duration/2., 'cycle', 1, 'phase', 0, 'delay', 0); j=j+1;
ex_typing(i) = stims_repeat(stim, n_repeats, 'framerate', framerate); i = i+1; 

%% Moving Bar: Probing Wide-field effect.
% A bar of width 160 mm (2.4º) moving at 500 mm per s (7.5º per s). Johnston and Lagnado (2016)
% Stim size: 128 px ~ 2600 um
n_repeats = 2;
moving_bar('barColor', 'dark','c_mask', [0 1 1], 'barWidth', 150, 'barSpeed', 1.4, 'angle_every', 45, 'N_repeat', 8 * n_repeats); 
%%
moving_bar('barColor','white','c_mask', [0 1 1], 'barWidth', 150, 'barSpeed', 1.4, 'angle_every', 45, 'N_repeat', 8 * n_repeats);

%% Repeat natural movies: Cell's reproducibility to natural movies? (1 min)
% combination of multiple movies.
params = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'length', 0.2, 'repeat', 3,... 
                'mov_id', 1, 'startframe', 600, 'seed', 7,... 
                'ndims', [256,256,3], 'scale', 0.5, 'jitter_var', 0.5, 'c_mask', [0, 1, 1]);
            
params(2) = struct('function', 'naturalmovie2', 'framerate', 30, 'jumpevery', 60,... 
                'length', 0.2, 'repeat', 3,... 
                'mov_id', 2, 'startframe', 200, 'seed', 7,... 
                'ndims', [256,256,3], 'scale', 0.5, 'jitter_var', 0.5, 'c_mask', [0, 1, 1]);
%ex = run_naturalmovie(movies, params); % mov = 4-D matrix
% script for playing stimulus. 'params' should be defined in advance.
run_stims

%% Whitenoise and natural movie stimulus
% intensity factor = 0.7 @ initdisp (0306 2018)
% 1.4 mm aperture : 2.7 mm [64 64] mov, 35 grid checkers  1.48 mm
% 1.3 mm apergure : 1.36 mm [64 64] mov
runjuyoung;
%%
replay % for runjuyoung

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


