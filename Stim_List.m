commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')
% common parameters for all stimuli
debug = 0;
% screen initialization -> bg color and pd setting
% offset location? 
    % Modify screen.rect by OffsetRect(oldRect,x,y) @ InitScreen    
%% Test screen (increasing disc?)
testscreen_colors;
%%
testscreen_annulus;

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
%%
% intensity factor = 0.7 @ initdisp (0306 2018)
runjuyoung;

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

%% RF 1: 60 um checkers
stimRF_60 = RF_Juyoung('movieDurationSecs', (60*15), ... % 15 min
                    'checkerSizeXum', 60, ...
                    'checkerSizeYum', 60, ...
                    'stimSizeXYum', 2400*[1 1], ...
                    'c_channels', [0 1 0], ...
                    'recreation', 'no');
                
%% identification OMS g-cells and PA a-cells?
% differential step stimulus
% Bar width = 100 um
%OMS_diff_Grating_Phase_Scan; % Arrow? next session (e.g. phase)
                             % Esc throws an error.
