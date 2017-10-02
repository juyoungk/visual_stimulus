% RF 0: David stim for online RF mapping
% always 38 by 38 checkers
% 50 um checker? 19 px /2 
 
% rfMap1(300,BoxL,38*BoxL);
commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')

% flash & grating
flash_annulus_stims('radius', 2500, 'halfPeriodSecs', 1, 'Ncycle', 3);

% Moving Bar
% a bar of width 160 mm (2.4º) moving at 500 mm per s (7.5º per s). 
% Johnston and Lagnado 2016
moving_bar('barColor', 'white', 'barWidth', 150, 'barSpeed', 1.4, 'N_repeat', 2)
moving_bar('barColor',  'dark', 'barWidth', 150, 'barSpeed', 1.4, 'N_repeat', 2)

% identification OMS g-cells and PA a-cells?
% differential step stimulus
% Bar width = 100 um
OMS_diff_Grating_Phase_Scan; %

% OMS jitter
% 1 repeat has 2 sessions (global-differntial)
% press 'q' to jump to next session. Not Arrows.
OMS_jitter('seed', 1, 'sDuration', 10, 'N_repeats', 3); % 1 min
%OMS_jitter('seed', 2, 'sDuration', 10, 'N_repeats', 3); % 1 min
%OMS_jitter('seed', 3, 'sDuration', 10, 'N_repeats', 3); % 1 min


% RF 1: 50 um checkers
stimRF_50 = RF_Juyoung( 'movieDurationSecs', (60*20), ... % 20 min
                    'checkerSizeXum', 50, ...
                    'checkerSizeYum', 50, ...
                    'stimSizeXYum', 2000*[1 1], ...
                    'recreation', 'no');

% RF 2: 100 um checkers
% stimRF_100 = RF_Juyoung( 'movieDurationSecs', (60*5), ... % 5 min
%                     'checkerSizeXum', 100, ...
%                     'checkerSizeYum', 100, ...
%                     'stimSizeXYum', 2000*[1 1], ...
%                     'recreation', 'no');