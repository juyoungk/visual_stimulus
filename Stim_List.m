commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')
addpath(pwd);
% common parameters for all stimuli
debug = 0;
% screen initialization -> bg color and pd setting
% pd
% background

%% Test screen (increasing disc?)
testscreen_colors;
%% test flash
flash_annulus_stims('radius', 2400, 'color', [0 1 1], 'halfPeriodSecs', 1, 'Ncycle', 30);

%% flash (center only)
flash_annulus_stims('radius', 600, 'color', [0 1 1], 'halfPeriodSecs', 2, 'Ncycle', 20);
%% flash (full-field)
flash_annulus_stims('radius', 2400, 'color', [0 1 0], 'halfPeriodSecs', 2, 'Ncycle', 20);
    %% flash (full-field)
    flash_annulus_stims('radius', 2400, 'color', [0 1 1], 'halfPeriodSecs', 2, 'Ncycle', 20);
    %% flash (full-field)
    flash_annulus_stims('radius', 2400, 'color', [0 0 1], 'halfPeriodSecs', 2, 'Ncycle', 20);

%% anuulus stim?


%% OMS jitter
% 1 repeat has 2 sessions (global-differntial)
% press 'q' to jump to next session. Not Arrows (rotation)
% only 10s sequence
OMS_jitter_color_mask('seed', 1, 'sDuration', 10, 'N_repeats', 3, 'color_Mask', [0 1 1]); % 1 min (sDuration x 2 x N_repeats)
OMS_jitter_color_mask('seed', 2, 'sDuration', 10, 'N_repeats', 3, 'color_Mask', [0 1 1]); % 1 min (sDuration x 2 x N_repeats)
%% Differential motion for speed tuning (interleaved every 10s?)
% Check the text location
OMS_jitter_color_mask('seed', 3, 'sDuration', 300, 'N_repeats', 1, 'color_Mask', [0 1 1]); % 10 min (sDuration x 2 x N_repeats)
%% Moving Bar
% % a bar of width 160 mm (2.4º) moving at 500 mm per s (7.5º per s). 
% % Johnston and Lagnado 2016
% Only UV (2) color cahnnels
moving_bar('barColor', 'white', 'barWidth', 150, 'barSpeed', 1.4, 'N_repeat', 10); 
%%
moving_bar('barColor',  'dark', 'barWidth', 150, 'barSpeed', 1.4, 'N_repeat', 10);

%% identification OMS g-cells and PA a-cells?
% differential step stimulus
% Bar width = 100 um
OMS_diff_Grating_Phase_Scan; % Arrow? next session (e.g. phase)
                             % Esc throws an error.

%% RF 1: 60 um checkers
stimRF_60 = RF_Juyoung('movieDurationSecs', (60*5), ... % 5 min
                    'checkerSizeXum', 60, ...
                    'checkerSizeYum', 60, ...
                    'stimSizeXYum', 2400*[1 1], ...
                    'c_channels', [0 1 1], ...
                    'recreation', 'no');