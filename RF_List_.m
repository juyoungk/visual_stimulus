% RF 0: David stim for online RF mapping
% always 38 by 38 checkers
% 50 um checker? 19 px /2 
 
% rfMap1(300,BoxL,38*BoxL);
commandwindow % Change focus to command window
addpath('HelperFunctions/')

%flash

% moving _bar
moving_bar; % white

moving_bar; % dark

% RF 1: 50 um checkers
stimRF_50 = RF_Juyoung( 'movieDurationSecs', (60*15), ... % 15 min
                    'checkerSizeXum', 50, ...
                    'checkerSizeYum', 50, ...
                    'stimSizeXYum', 2000*[1 1], ...
                    'recreation', 'no');

% RF 2: 100 um checkers
stimRF_100 = RF_Juyoung( 'movieDurationSecs', (60*5), ... % 5 min
                    'checkerSizeXum', 100, ...
                    'checkerSizeYum', 100, ...
                    'stimSizeXYum', 2000*[1 1], ...
                    'recreation', 'no');