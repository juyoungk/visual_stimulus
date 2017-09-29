function DL_movbar(repeat, bar_input, barWidth, boxSize, stimSize)
% DL_movbar(bar_input, barWidth, boxSize, stimSize)
% DL_MOVBAR displays moving bars.
%
% bar_input is a matrix of parameters of bars (2-N arrays)
%   1st row: contrast of moving bar (1=black; 0='mean')
%   2nd row: speed of moving bar (number of pixels to move per flip (ifi))
% barWidth is the width of bars [pixel] (default = 24)
% boxSize and stimSize are the parameters of DL_rfmap (for consistency)
%
% by Dongsoo Lee (created 17-01-10, edited 17-03-08)
t_start = datestr(datetime('now'), 'yy-mm-dd HH:MM:SS');
% ----------------
% contrast_input = [  0.1    0.1     0.1     0.1     0.1  ...
%                     0.25   0.25    0.25    0.25    0.25 ...
%                     0.5    0.5     0.5     0.5     0.5  ...
%                     0.9    0.9     0.9     0.9     0.9  ];
% speed_input = [     0.25   0.5     1       2       4    ...
%                     0.25   0.5     1       2       4    ...
%                     0.25   0.5     1       2       4    ...
%                     0.25   0.5     1       2       4    ];

contrast_input = [                         0.1          ...
                                           0.25         ...
                                   0.5     0.5     0.5  ...
                                   0.9     0.9     0.9  ];
speed_input = [                            2            ...
                                           2            ...
                                   1       2       4    ...
                                   1       2       4    ];
%index = randperm(length(contrast_input));
index = [2 8 1 4 7 6 3 5]; % pseudorandom
contrast_temp = [];
speed_temp = [];
for ind = 1:length(index)
    contrast_temp(ind) = contrast_input(index(ind));
    speed_temp(ind) = speed_input(index(ind));
end
contrast_input = contrast_temp;
speed_input = speed_temp;
%------------------------
% number of arguments?
if nargin == 0
    repeat = 5
    bar_input = [contrast_input; speed_input];
    barWidth = 24;
    boxSize = 8;
    stimSize = boxSize * 32;
elseif nargin == 1
    %repeat = 5
    bar_input = [contrast_input; speed_input];
    barWidth = 24;
    boxSize = 8;
    stimSize = boxSize * 32;
elseif nargin == 2
    %repeat = 5
    %bar_input = [contrast_input; speed_input];
    barWidth = 24;
    boxSize = 8;
    stimSize = boxSize * 32;
elseif nargin == 3
    %repeat = 5
    %bar_input = [contrast_input; speed_input];
    %barWidth = 24;
    boxSize = 8;
    stimSize = boxSize * 32;
elseif nargin == 4
    %repeat = 5
    %bar_input = [contrast_input; speed_input];
    %barWidth = 24;
    %boxSize = 8;
    stimSize = boxSize * 32;
elseif nargin == 5
    %repeat = 5
    %bar_input = [contrast_input; speed_input];
    %barWidth = 24;
    %boxSize = 8;
    %stimSize = boxSize * 32;
end

% parameters
% -----------------------------------------------------------
barContrast = bar_input(1, :);              % [%]; contrast of moving bar (1=black; 0='mean')
barSpeed = bar_input(2, :);                 % [pixel/ifi]; number of pixels to move per flip (ifi)
%barWidth = 24;                             % [pixel]
%boxSize = 8;                               % [pixel]; size of box(DL_rfmap function)
%stimSize = boxSize * 32;                   % [pixel]; size of stimulus(``)

NUM_OF_BARS = size(bar_input, 2);           % [number]; number of bars
PAUSETIME = 0.2;                            % [sec]
WAITFRAMES = 1;                             % [frames]; how many ifi
% salamander: 50 micron = 1 degree
% -----------------------------------------------------------

try
    % check if the installed Psychtoolbox is based on OpenGL ('Screen()'),
    %       and provide a  consistent mapping of key codes
    AssertOpenGL;
    KbName('UnifyKeyNames');                        %  = PsychDefaultSetup(1);
    
    %Screen('Preference', 'ScreenToHead', 1, 1, 0); % use this in a real experiment
    %Screen('Preference', 'SkipSyncTests', 1);       % don't use this in a real experiment
    
    % load KbCheck because it takes some time to read for the first time
    while KbCheck(); end
    
    ListenChar(2);                                  % suppress output of keypresses
    
    % get the screen numbers & draw to the external screen if available
    myScreen = max(Screen('Screens'));
    
    % open an on screen window
    [myWindow, windowRect] = Screen('OpenWindow', myScreen, 255/2);
    Screen('ColorRange', myWindow, 1, [], 1);
    % set the maximum priority number
    Priority(MaxPriority(myWindow));
    
    % get index of black and white
    black = BlackIndex(myScreen);                   % 0
    white = WhiteIndex(myScreen);                   % 1
    %meanIntensity = ((black + white + 1)/2) - 1;    % 127
    meanIntensity = (black + white)/2;              % 0.5
    
    % get inter-flip interval (inverse of frame rate)
    ifi = Screen('GetFlipInterval', myWindow);
    
    % get the size of the on screen window
    [xSize, ySize] = Screen('WindowSize', myWindow);
    
    % set photodiode
    PHOTODIODE = ones(4, 1);
    PHOTODIODE(1, :) = round(xSize/10 * 9.0 - 65);
    PHOTODIODE(2, :) = round(ySize/10 * 1.6 - 65);
    PHOTODIODE(3, :) = round(xSize/10 * 9.0 + 65);
    PHOTODIODE(4, :) = round(ySize/10 * 1.6 + 65);
    
    % set moving bar frame (to be consistent with [DL_rfmap] function)
    stimSize = ceil(stimSize/boxSize) * boxSize;
    numHBoxes = ceil(stimSize/boxSize/2) * 2;
    stimSize = numHBoxes * boxSize;
    xOffset = floor((xSize/2 - stimSize/2)/boxSize) * boxSize;
    yOffset = floor((ySize/2 - stimSize/2)/boxSize) * boxSize;
    
    % set moving bar parameters
    bar = ones(4, 1);                               % moving bar
    bar(1, :) = xOffset;                            % left border
    bar(2, :) = yOffset;                            % upper border
    bar(3, :) = xOffset + barWidth;                 % right border
    bar(4, :) = yOffset + stimSize;                 % bottom border
    %barIntensity = black + round((meanIntensity - black) * (1 - barContrast));  % [no unit(?)], actual value
    barIntensity = black + (meanIntensity - black) * (1 - barContrast);  % [no unit(?)], actual value
    
    % construct the moving bar (depends on the time unit "ifi")
    movingbar = {};
    for ind = 1:NUM_OF_BARS
        movingbar_temp = bar;
        while movingbar_temp(3, end) < xOffset + stimSize
            movingbar_temp = [movingbar_temp movingbar_temp(:, end) + [barSpeed(ind) 0 barSpeed(ind) 0]'];
        end
        movingbar{ind} = floor(movingbar_temp);
    end
    
    % prepare for the first screen
    Screen('FillOval', myWindow, black, PHOTODIODE);
    Screen('Flip', myWindow);
    HideCursor();
    KbWait();
    % wait for keyboard input
    KbEventFlush();
    KbQueueCreate();
    KbQueueStart();
    pause(PAUSETIME);
    
    % to start recording computer (one frame earlier)
    Screen('FillOval', myWindow, 0.5 * white, PHOTODIODE);
    vbl = Screen('Flip', myWindow);
    
    % draw moving bars
    tic
    for r = 1:repeat
        for i = 1:NUM_OF_BARS
            for j = 1:size(movingbar{i}, 2) - 1 % (will not draw the last)
                if j == 1                               % first
                    Screen('FillRect', myWindow, barIntensity(i), movingbar{i}(:, j));
                    if i == 1                            % - first of each repeat
                        Screen('FillOval', myWindow, white, PHOTODIODE);
                    else
                        Screen('FillOval', myWindow, 0.7 * white, PHOTODIODE);
                    end
                    Screen('DrawingFinished', myWindow);
                    vbl = Screen('Flip', myWindow, vbl + (WAITFRAMES - 0.5) * ifi);
                elseif j == size(movingbar{i}, 2) - 1   % the second last (will not draw the last)
                    Screen('FillRect', myWindow, barIntensity(i), movingbar{i}(:, j));              
                    Screen('FillOval', myWindow, black, PHOTODIODE);
                    Screen('DrawingFinished', myWindow);
                    vbl = Screen('Flip', myWindow, vbl + (WAITFRAMES - 0.5) * ifi);
                    if r == repeat && i == NUM_OF_BARS  % add one frame at the last
                        Screen('FillRect', myWindow, barIntensity(i), movingbar{i}(:, j));              
                        Screen('FillOval', myWindow, white, PHOTODIODE);
                        Screen('DrawingFinished', myWindow);
                        vbl = Screen('Flip', myWindow, vbl + (WAITFRAMES - 0.5) * ifi);
                    end
                else                                    % the rest
                    Screen('FillRect', myWindow, barIntensity(i), movingbar{i}(:, j));
                    Screen('FillOval', myWindow, black, PHOTODIODE);
                    Screen('DrawingFinished', myWindow);
                    vbl = Screen('Flip', myWindow, vbl + (WAITFRAMES - 0.5) * ifi);
                end
            end
            % keyboard check
            if KbQueueCheck(-1);
                break;
            end
            % pause
            % pause(PAUSETIME);
        end
    end
    toc
    
    % wait 
    Screen('FillOval', myWindow, black, PHOTODIODE);
    vbl = Screen('Flip', myWindow);
    pause(15);
    
    t_end = datestr(datetime('now'), 'yy-mm-dd HH:MM:SS');
    
    %  -- save parameters of experiment --
    ex.box_size = boxSize;
    ex.stim_size = stimSize;
    
    ex.NUM_OF_BARS = NUM_OF_BARS;
    ex.bar_width = barWidth;
    
    ex.bar_contrast_input = barContrast;
    ex.bar_intensity_output = barIntensity;
    ex.bar_speed = barSpeed;
    ex.bar = movingbar;
    
    ex.window_size = windowRect;
    ex.ifi = ifi;
    ex.pausetime = PAUSETIME;
    ex.photodiode = PHOTODIODE;
    ex.waitframe = WAITFRAMES;

    ex.num_input_arg = nargin;
    ex.species = 'salamander';
    ex.location = 'D239';
    ex.monitor = 'SONY';
    ex.mea = '100/10';
    ex.electrode = 1;
    ex.start_time = char(t_start);
    ex.end_time = char(t_end);
    ex.repeat = repeat;
    ex.black = black;
    ex.white = white;
    ex.mean_intensity = meanIntensity;
    ex.photodiode_index = {[0.5 1 0.7 1], 'start signal', 'start of each repeat', 'first frame', 'the last frame + 1'};
    
    ex.bar_index = index;
    num_frame = [];
    for l = 1:length(movingbar)
        num_frame(l) = length(movingbar{l});
    end
    ex.num_barframe = num_frame;
    
    date_today = datestr(datetime('today'), 'yy-mm-dd');
    filename = [date_today '-mb' '.mat'];
    
    id = 1;
    while exist(fullfile('/home/dsnl/Documents/MATLAB/archive/', filename), 'file') == 2
        filename = [sprintf('%s-%s-%d', date_today, 'mb', id), '.mat'];
        id = id + 1;
        if id > 20
            break;
        end
    end
    save(['/home/dsnl/Documents/MATLAB/archive/' filename], 'ex');
    % -------------------------------------
    
    Screen('CloseAll');
    ShowCursor();
    ListenChar(0);
catch exception
    Screen('CloseAll');
    ShowCursor();
    ListenChar(0);
    exception.identifier();
end
