function screen = InitScreen(debugging, width, height, rate, varargin)
    % Initializes the Screen.
    % Return 'screen' variable which contains various infos.
    % debugging 1 = test mode. Ignore timing and resolution setting.
    % [width, height, rate] matters only when you are using debugging=1. if
    % you are using labtop, it will automatically skip this parameters.
    % The idea here is that you can call this function from within a given
    % stimulus where the 2nd parameter might or might no be defined. If it
    % is defined this function does nothing but if it is not defined then
    % this function initializes the screen.
    
    p = ParseInput(varargin{:});
    bg_color = p.Results.bg_color;

    AssertOpenGL;

    % Get the list of screens and choose the one with the highest screen number.
    % screen.screenNumber = 2;
    n = max(Screen('Screens'));
    %
    resolutions = cell(1, n);
    cur_display_Res_width = 100000000;
    for i = 1:n
        resolutions{i} = Screen('resolution', i);
        if resolutions{i}.width < cur_display_Res_width
            cur_display_Res_width = resolutions{i}.width
            % pick screen number whose resolution is the lowest among
            % others.
            screen.screenNumber = i
        end
    end
    %screen.screenNumber = n;
    %screen.screenNumber = 2;
    % if Nominal rate is 0, (running from a laptop) Psychtoolbox is failing
    % to initialize the screen because there are synchronization problems. I
    % don't care about those problems when running in my laptop. Experiment
    % would never be run under those conditions. Force it to start anyway
    screen.rate = Screen('NominalFrameRate', screen.screenNumber);
    %featureLevel = 2;
    %PsychDefaultSetup(featureLevel);
    if any([screen.rate == 0, screen.screenNumber ==0])
        Screen('Preference', 'SkipSyncTests',1);
        Screen('Preference', 'VisualDebugLevel', 3);
        screen.rate = 100; % why 100??
        screen.ifi=(0.03322955)/2.;
        %[screen.w screen.rect] = Screen('OpenWindow',screen.screenNumber, backColor, [10 10 1000 1000]);
        [screen.w screen.rect] = PsychImaging('OpenWindow', screen.screenNumber, bg_color, [10 10 1024 778]);
    elseif debugging ==1
        Screen('Preference', 'SkipSyncTests',1);
        Screen('Preference', 'VisualDebugLevel', 3);
        %[screen.w screen.rect]=Screen('OpenWindow',screen.screenNumber, backColor, [10 10 1000 1000]);
        [screen.w screen.rect] = PsychImaging('OpenWindow', screen.screenNumber, bg_color, [0 10 1024 778]);
        screen.ifi=Screen('GetFlipInterval', screen.w);
        Priority(1);
    else
        %Screen('Resolution', screen.screenNumber, width, height, rate);
        %[screen.w screen.rect]=Screen('OpenWindow',screen.screenNumber, backColor);
        Screen('Preference', 'VisualDebugLevel', 3);
        % Setup PsychImaging pipeline, allows for fast drawing
        PsychImaging('PrepareConfiguration');
        PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
        PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
        % Open the window, fullscreen is default
        [screen.w screen.rect] = PsychImaging('OpenWindow', screen.screenNumber, bg_color);

        screen.ifi=Screen('GetFlipInterval', screen.w);
        %HideCursor();
        Priority(1);
    end
    % refresh interval of the monitor
    %screen.waitframes = round(.033*screen.rate);
    
    % Find the color values which correspond to white and black.
    screen.white=WhiteIndex(screen.screenNumber);
    screen.black=BlackIndex(screen.screenNumber);
    screen.gray=GrayIndex(screen.screenNumber);

    % background?
    screen.backColor = bg_color;
    screen.bg_color = bg_color;
    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
	screen.gray = floor((screen.white+screen.black)/2);
    
         
    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if screen.gray == screen.white
      screen.gray = screen.white/2;
    end

    [screen.center(1,1) screen.center(2,1)] = WindowCenter(screen.w);%[screenX screenY]/2;
    % pixel number along X & Y
    [screen.size(1) screen.size(2)] = Screen('WindowSize', max(Screen('Screens')));
    [screen.sizeX screen.sizeY]     = Screen('WindowSize', max(Screen('Screens')));
    
    %
    screen.framesPerFlip = round( screen.rate * p.Results.stimFrameInterval );
    % Nominal-rate-optimized stimulus flip interval (not rate)
    screen.frameTime = screen.ifi * screen.framesPerFlip;
    
    
    %if mod(screen.rate,2)
    %    answer = questdlg(['Screen Rate is a non (', num2str(screen.rate), ...
    %        'Hz). Do you want to continue or abort?'], 'Frame Rate', 'Abort', 'Continue', 'Abort');
    %    if strcmp(answer, 'Abort')
    %        error('Change the monitor rate');
    %    end
    %end

    % Set some text properties
    Screen('TextFont', screen.w, 'Helvetica'); % 'Ariel' doesn't work in Macbook
    Screen('TextSize', screen.w, 24);
    
    % timestamps initialization.
    screen.vbl = 0;
end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.

    % Gabor parameters
    p.addParamValue('bg_color', 0, @(x) x>=0 && x<=255); %gray
    p.addParameter('stimFrameInterval', 0.033, @(x)x>=0);
    % 
    p.parse(varargin{:});
end
