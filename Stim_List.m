%commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')
% common parameters for all stimuli
debug = 0;
% screen initialization -> bg color and pd setting
% offset location? 
    % Modify screen.rect by OffsetRect(oldRect,x,y) @ InitScreen
% ex_today = datestr(now, 'yy-mm-dd');
% basedir = fullfile('logs/', ex.today);
i = 1; % ex or FOV id
%% Test screen (increasing disc?)
testscreen_colors;
%%
testscreen_annulus;

%% Checkerboard style stim definition (Functional typing)
% size in mm, period in secs
% BG mode: 0 - No t BG, 1 - Checkers (same pattern as center)
% BG size = aperture size.
stim =[];
stim    = struct('ndims',  [1,1], 'sizeCenter', 0.6, 'BG', 0, 'color', [0 1 0], 'half_period', 1., 'cycle', 1, 'phase', 0, 'delay', 0);
stim(2) = struct('ndims',  [1,1], 'sizeCenter', 0.6, 'BG', 0, 'color', [0 0 1], 'half_period', 1., 'cycle', 1, 'phase', 0, 'delay', 0);
stim(3) = struct('ndims',  [1,1], 'sizeCenter', 0.6, 'BG', 0, 'color', [0 1 1], 'half_period', 1., 'cycle', 1, 'phase', 0, 'delay', 0);
% RF or Dendritic field size of the bipolar cells ~ 23 um (W3 paper)
stim(4) = struct('ndims',[12, 1], 'sizeCenter', 0.6, 'BG', 0, 'color', [0 1 1], 'half_period', 1., 'cycle', 2, 'phase', 0, 'delay', 0);
stim(5) = struct('ndims',[25, 1], 'sizeCenter', 0.6, 'BG', 0, 'color', [0 1 1], 'half_period', 1., 'cycle', 2, 'phase', 0, 'delay', 0);
% global and diff step stimulus
%stim(6) = struct('ndims',[1,25], 'sizeCenter', 0.6, 'BG', 1, 'color', [0 1 1], 'half_period', 2., 'cycle', 2, 'phase', 0, 'delay', 0);
%stim(7) = struct('ndims',[1,25], 'sizeCenter', 0.6, 'BG', 1, 'color', [0 1 1], 'half_period', 2., 'cycle', 2, 'phase', 0, 'delay', 0.5);
%stim(2) = struct('ndims', [10,10], 'sizeCenter', 0.6, 'BG', 0, 'color', [0 0 1], 'half_period', 0.5, 'cycle', 2, 'phase', 0);
%stim(9) = struct('ndims', [10,10], 'sizeCenter', 0.6, 'BG', 1, 'color', [0 1 0], 'half_period', 0.5, 'cycle', 2, 'phase', 0);
%
n_repeats = 1;
%
ex_fov = stims_repeat(stim, n_repeats); % + options % save the stim in log forder?
 
%%
i = i + 1; % FOV (or ex) index
ex_fov(i) = stims_repeat(stim, n_repeats); % + options % save the stim in log forder?


%% Whitenoise and natural movie stimulus
% intensity factor = 0.7 @ initdisp (0306 2018)
runjuyoung;


%% flash (center only)
flash_annulus_stims('radius', 300, 'color', [0 1 0], 'halfPeriodSecs', 2.5, 'Ncycle', 20);
%% flash
flash_annulus_stims('radius', 600, 'color', [0 1 0], 'halfPeriodSecs', 2.5, 'Ncycle', 20);
%%
%flash_annulus_stims('radius', 1200, 'color', [0 1 0], 'halfPeriodSecs', 2.5, 'Ncycle', 20);
%% Moving Bar
% % a bar of width 160 mm (2.4º) moving at 500 mm per s (7.5º per s). 
% % Johnston and Lagnado 2016
% stim size: 64 px ~ 1300 um
moving_bar('barColor','dark', 'c_mask', [0 1 0], 'barWidth',150, 'barSpeed', 1.4, 'N_repeat', 24); 
%%
moving_bar('barColor','white','c_mask', [0 1 0], 'barWidth',150, 'barSpeed', 1.4, 'N_repeat', 24);

%% Global/Differential motion to compute avg motion feature (UV or Blue)
% Normally distributed jitter sequence. (default variance = 0.5) 
% press 'q' to jump to next session. Not Arrows (rotation)
OMS_jitter_color_mask('seed', 1, 'sDuration', 15, 'N_repeats', 5, 'random_repeat', true, 'color_Mask', [0 1 0], 'c_intensity', 0.7); % 2.5 min (sDuration x 2 x N_repeats)
%%
OMS_jitter_color_mask('seed', 1, 'sDuration', 15, 'N_repeats', 5, 'random_repeat', true, 'color_Mask', [0 1 0], 'background', false, 'c_intensity', 0.7); % 2.5 min (sDuration x 2 x N_repeats)
%OMS_jitter_color_mask('seed', 1, 'sDuration', 10, 'N_repeats', 20, 'random_repeat', true, 'color_Mask', [0 1 1], 'sync_to_ch', 2); % 10 min (sDuration x 2 x N_repeats)
%%
replay % for runjuyoung

%%
% 10x objective lens for stim?? and calibration

                
%% identification OMS g-cells and PA a-cells?
% differential step stimulus
% Bar width = 100 um
%OMS_diff_Grating_Phase_Scan; % Arrow? next session (e.g. phase)
                             % Esc throws an error.
