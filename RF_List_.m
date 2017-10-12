 % rfMap1(300,BoxL,38*BoxL);
commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')

% common parameters for all stimuli
debug = 0;
% screen initialization -> bg color and pd setting
% pd
% background

% if 'ex' has been initialized, skip the initialization each function.

% Stimulus List
% flash & grating
flash_annulus_stims('radius', 2000, 'halfPeriodSecs', 2, 'Ncycle', 10);

% Moving Bar
% a bar of width 160 mm (2.4º) moving at 500 mm per s (7.5º per s). 
% Johnston and Lagnado 2016
moving_bar('barColor', 'white', 'barWidth', 150, 'barSpeed', 1.4, 'N_repeat', 10)
moving_bar('barColor',  'dark', 'barWidth', 150, 'barSpeed', 1.4, 'N_repeat', 10)

% OMS jitter
% 1 repeat has 2 sessions (global-differntial)
% press 'q' to jump to next session. Not Arrows (rotation)
OMS_jitter('seed', 1, 'sDuration', 10, 'N_repeats', 3); % 1 min (sDuration x 2 x N_repeats)
OMS_jitter('seed', 2, 'sDuration', 10, 'N_repeats', 3); % 1 min
OMS_jitter('seed', 3, 'sDuration', 10, 'N_repeats', 3); % 1 min


% RF 1: 50 um checkers
stimRF_60 = RF_Juyoung( 'movieDurationSecs', (60*20), ... % 20 min
                    'checkerSizeXum', 60, ...
                    'checkerSizeYum', 60, ...
                    'stimSizeXYum', 2400*[1 1], ...
                    'recreation', 'no');

% identification OMS g-cells and PA a-cells?
% differential step stimulus
% Bar width = 100 um
%OMS_diff_Grating_Phase_Scan; % Arrow? next session (e.g. phase)
                             % Esc throws an error.

                
                
% RF 2: 100 um checkers
% stimRF_100 = RF_Juyoung( 'movieDurationSecs', (60*5), ... % 5 min
%                     'checkerSizeXum', 100, ...
%                     'checkerSizeYum', 100, ...
%                     'stimSizeXYum', 2000*[1 1], ...
%                     'recreation', 'no');