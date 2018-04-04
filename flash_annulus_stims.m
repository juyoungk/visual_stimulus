function [log] = flash_annulus_stims(varargin)
    addpath('HelperFunctions/')
    addpath('Functions/')
    % 
    p=ParseInput(varargin{:});
    %
    centerX = p.Results.centerX;    %offset from the center
    centerY = p.Results.centerY;
    stimFrameInterval = p.Results.stimFrameInterval;
    seed = p.Results.seed;
    duration = p.Results.DurationSecs;
    contrast = p.Results.objContrast;
    Ncycle = p.Results.Ncycle;      % # of trials. avg # in analysis
    halfperiod = p.Results.halfPeriodSecs;
try
    % monitor setting: 
    screen = InitScreen(0);
    % BG
    Screen('FillRect', screen.w, screen.bg_color);
    %
    color_mask = p.Results.color;
    OnColor = color_mask * screen.white/2.;
    OffColor = color_mask * screen.black; 
    bgColor = color_mask * screen.black;
 
    % flash stimulus
    r = p.Results.radius; % in microns
    radiusDot = Pixel_for_Micron(r);
    % 
    halfperiodGrating = halfperiod;
    
    % Tot time = [half period(1.5)*2*Ncycle+ 1.5]* N (radius,8) = 252
    % Tot time (grating) =Nwidth(3)*Nphase(4)*Ncycle(10)*halfperiod(1.)*2 = 240s
 
    % time & duration parameters
    pause = 1;
    
    % frame parameters
    vbl = 0; vbl_prev =0; stop =0;
    
    % grating or checker
    StimSizeX = Pixel_for_Micron( 1000 ); StimSizeY = StimSizeX; Checker_Y = StimSizeY; 
    Checker_X = Pixel_for_Micron( [50, 100] );
    Nphase = 4;
    %
    % stimulus 1: Simple dot flash with increasing radius (Measure the surround inhibition)
    %WaitStartKeyTrigger(screen, 'TEXT', 'Dot stimulus', 'posX', 0.75*screen.sizeX);
    WaitStartKey(screen.w, 'expName', 'Dot stimulus');
    % centered at screen.rect
    [vbl, log] = DotFlashStim(screen, vbl, halfperiod, Ncycle, centerX, centerY, radiusDot, OnColor, OffColor);    
 
    % stimulus 4: Nonlinear spatial summation (X)
    %WaitStartKeyTrigger(screen, 'TEXT', 'Periodic Checkers (X)', 'posX', 0.75*screen.sizeX);
    
    %WaitStartKey(screen.w, 'expName', 'Periodic Checkers (X)');
    %[vbl, log] = CheckerPeriodicStim(screen, vbl+pause, contrast, halfperiodGrating, Ncycle, centerX, centerY, ...
    %                            StimSizeX, StimSizeY, Checker_X, Checker_Y, 0, Nphase, 'log', log);
       
    disp log;
    Screen('CloseAll');
    Priority(0);
    ShowCursor();
    
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function [vbl, log] = CheckerPeriodicStim(screen, vbl, contrast, halfperiod, Ncycle, centerX, centerY, ...
                                StimSizeX, StimSizeY, CheckerSizeX, CheckerSizeY, maskRadius, Nphase, varargin)
%
  p = ParseInput(varargin{:});
 %pd = DefinePD_shift(screen.w);
 [pd, pd_color_max] = DefinePD_shift(screen.w);
log = addLog(p.Results.log);
vbl0 = vbl;
stopFLAG =0; cur_frame = 0;
MyKbQueueInit(); pressed = 0;
%
rotation = p.Results.rotationAngle;                          

for j=1:length(CheckerSizeX)
    % # of checkers (not the size)
    Nx = ceil(StimSizeX/CheckerSizeX(j));
    Ny = ceil(StimSizeY/CheckerSizeY);
    [a1, a2] = GetCheckers(Nx, Ny, 1, contrast, screen.gray);
    % new checker size in order to cover the stim size
    sizeX = Nx * CheckerSizeX(j);
    sizeY = Ny * CheckerSizeY;
    %
    for k=1:Nphase
        % Define the obj Destination Rectangle
        objRect = SetRect(0, 0, sizeX, sizeY);
        objRect = CenterRect(objRect, screen.rect);
        centerXph = centerX + (k-1)*CheckerSizeX(j)/Nphase;
        centerYph = centerY + (k-1)*CheckerSizeX(j)/Nphase;
        objRect = OffsetRect(objRect, centerXph, centerY);    
        if rotation == 90
            objRect = OffsetRect(objRect, centerX, centerYph);    
        end
            
        for i=1:2*round(Ncycle)
            % color? matrix, a texture pointer
            if mod(i,2)
                color = a1;
                pd_color =  j/length(CheckerSizeX)/2.*pd_color_max;
            else 
                color = a2;
                pd_color = screen.black;
            end
            % Obtain an index of OpenGL texture which may be passed to 'DrawTexture'
            objTex  = Screen('MakeTexture', screen.w, color);
            % display last texture
            Screen('DrawTexture', screen.w, objTex, [], objRect, rotation, 0);
            % PD
            Screen('FillOval', screen.w, pd_color, pd);
            % PD is max white for the 1st frame for triggering
            if cur_frame==0
                Screen('FillOval', screen.w, pd_color_max, pd);
            end
            cur_frame = cur_frame + 1;
            %
            vbl = Screen('Flip', screen.w, vbl + halfperiod - screen.ifi/2);
            %
            pressed = KbQueueCheck();
            if (pressed)
                stopFLAG=1; break; 
            end
        end % reverse grating loop
        if stopFLAG, break; end;
        pause(1.25);
    end %phase scan (no PD coding)
    if stopFLAG, break; end;
    pause(2.25);
end %grating width scan
log = addLog(log, 'duration', vbl-vbl0);
KbQueueFlush();
end

function [vbl, log] = DotFlashStim(screen, vbl, halfperiod, Ncycle, centerX, centerY, radius, OnColor, OffColor, varargin)    
% CenterX = 0 means at the center of the screen.
  p = ParseInput(varargin{:});
log = addLog(p.Results.log);
[pd, pd_color_max] = DefinePD_shift(screen.w);
vbl0 = vbl;
stopFLAG = 0;
cur_frame = 0;    %current frame number
MyKbQueueInit(); pressed = 0;
% loop
for j=1:length(radius)
    rect = RectForScreen(screen, 2*radius(j), 2*radius(j), centerX, centerY);
    for i=1:2*round(Ncycle)
        if mod(i,2)==1
            color =OnColor;
            pd_color = pd_color_max*j/length(radius)/2.; 
        else
            color=OffColor; 
            pd_color = screen.black;
        end;
        
        % bg color setting
        Screen('FillRect', screen.w, screen.bg_color);
        % Draw Dot
        Screen('FillOval', screen.w, color, rect);
        % PD: intensity coding. Cut the max white at half to avoid false
        % triggering
        Screen('FillOval', screen.w, pd_color, pd);
        if cur_frame==0
            Screen('FillOval', screen.w, pd_color_max, pd);
        end
        cur_frame = cur_frame + 1;
        % Flip
        vbl = Screen('Flip', screen.w, vbl + halfperiod - screen.ifi/2);
        if cur_frame==1, vbl0 = vbl; end;
        %
        pressed = KbQueueCheck();
        if (pressed)
            stopFLAG=1; break; 
        end
    end
    if stopFLAG, break; end;
    %pause(halfperiod);
end
pause(halfperiod);  %for correct estimation of duration
log = addLog(log, 'duration', vbl-vbl0+halfperiod);
KbQueueFlush();
end

function [vbl, log] = AnnulusFlashStim(screen, vbl, halfperiod, Ncycle, centerX, centerY, radius, annulusWidth, OnColor, OffColor, bgColor, varargin)    
%     
p = ParseInput(varargin{:});
pd = DefinePD;
vbl0 = vbl;
stopFLAG = 0;
cur_frame = 0;    %current frame number
log = addLog(p.Results.log);
MyKbQueueInit(); pressed = 0;
% Center dot
centerDotRec = RectForScreen(screen, 2*radius(1), 2*radius(1), centerX, centerY);
% loop
for j=1:length(radius)
    [outer_rect, inner_rect] = annulusRect(radius(j), annulusWidth, screen, centerX, centerY);
    for i=1:2*round(Ncycle)
        if mod(i,2)==1, color=OnColor; else color=OffColor; end;
        if j>1  % j=1? center dot only
            Screen('FillOval', screen.w, color, outer_rect);
            Screen('FillOval', screen.w, bgColor, inner_rect);
        end
        % Center dot (draw at the last)
        if strcmp(p.Results.centerDot, 'Yes') || j == 1
            Screen('FillOval', screen.w, color, centerDotRec);
        end
        % PD: intensity coding
        Screen('FillOval', screen.w, color*j/length(radius)/2, pd);
        if cur_frame==0
            Screen('FillOval', screen.w, screen.white, pd);
        end
        cur_frame = cur_frame + 1;
        % Flip
        vbl = Screen('Flip', screen.w, vbl + halfperiod - screen.ifi/2);
        if cur_frame==1, vbl0 = vbl; end;
        %
        pressed = KbQueueCheck();
        if (pressed)
            stopFLAG=1; break; 
        end 
    end
    if stopFLAG, break; end;
    %pause(halfperiod);
end
pause(halfperiod);
log = addLog(log, 'duration', vbl-vbl0+halfperiod);
KbQueueFlush();
end

function [vbl, log] = AnnulusBNoiseStim(screen, vbl, contrast, duration, stimFrameInterval, seed, ...
                            centerX, centerY, radius, annulusWidth, varargin)
p = ParseInput(varargin{:});
log = addLog(p.Results.log);
vbl0 = vbl;
stopFLAG = 0; cur_frame=0;
MyKbQueueInit(); pressed = 0;
% init random seed generator
randomStream = RandStream('mcg16807', 'Seed', seed);

% Frame? Refresh (nominal) rate of the display
% Flip? Designed stimulus rate
% # of nominal frames per one flip (=waitframes in Pablo's code)
framesPerFlip = round( screen.rate * stimFrameInterval );
% fprintf('[Ann B-Noise] framesPerFlip = %d\n',framesPerFlip);

% Nominal-rate-optimized stimulus frame
frameTime = screen.ifi * framesPerFlip;
framesN = round( duration / frameTime );
% BG
Screen('FillRect', screen.w, screen.gray);
pd = DefinePD;
bgColor = screen.gray;
%
for i=1:framesN
    colors = (rand(randomStream,1,length(radius))>.5)*2*screen.gray*contrast...
                + screen.gray*(1-contrast);
    for j=1:length(radius)-1 % -1 corresponds to radius(1), center dot. 
        [outer_rect, inner_rect] = annulusRect(radius(end-j+1), annulusWidth, screen, centerX, centerY);
        color = colors(end-j+1);
        if color>screen.white, color = screen.white; end;
        if color<screen.black, color = screen.black; end;
        
        Screen('FillOval', screen.w, color, outer_rect);
        Screen('FillOval', screen.w, bgColor, inner_rect);    
    end
    % Draw CenterDot at the last
    centerDotRec = RectForScreen(screen, 2*radius(1), 2*radius(1), centerX, centerY);
    color = colors(1);    
    Screen('FillOval', screen.w, color, centerDotRec);
    % PD
    Screen('FillOval', screen.w, color/2, pd);
    if cur_frame==0
        Screen('FillOval', screen.w, screen.white, pd);
    end
    cur_frame = cur_frame + 1;
    % Flip
    vbl = Screen('Flip', screen.w, vbl + (framesPerFlip-0.5)*screen.ifi );
    
    % stop if key is pressed
    if (KbCheck)
        stopFLAG=1; break; 
    end
end
log = addLog(log, 'duration', vbl-vbl0);
KbQueueFlush();
end

function [vbl, log] = AnnulusGNoiseStim(screen, vbl, contrast, duration, stimFrameInterval, seed, ...
                            centerX, centerY, radius, annulusWidth, varargin)
p = ParseInput(varargin{:});
log = addLog(p.Results.log);
vbl0 = vbl;
stopFLAG = 0; cur_frame=0;
MyKbQueueInit(); pressed = 0;
% init random seed generator
randomStream = RandStream('mcg16807', 'Seed', seed);

% # of nominal frames per one flip (=waitframes in Pablo's code)
framesPerFlip = round( screen.rate * stimFrameInterval );

% Nominal-rate-optimized stimulus frame
frameTime = screen.ifi * framesPerFlip;
framesN = round( duration / frameTime );
% BG
Screen('FillRect', screen.w, screen.gray);
pd = DefinePD;
bgColor = screen.gray;
%
for i=1:framesN
    for j=1:length(radius)
        [outer_rect, inner_rect] = annulusRect(radius(end-j+1), annulusWidth, screen, centerX, centerY);
        ranNum = randn(randomStream, 1);
        % 3*sigma = gray (mean)? 
        % ~35% of the max contrast of binary noise
        % Uniform dist = 14% of the max contrast of binary noise
        % Contrast here? = sqrt of variance
        color = ranNum*screen.gray/3*contrast + screen.gray;
        if color>screen.white, color = screen.white; end;
        if color<screen.black, color = screen.black; end;
        
        Screen('FillOval', screen.w, color, outer_rect);
        Screen('FillOval', screen.w, bgColor, inner_rect);
    end
    % PD
    Screen('FillOval', screen.w, color/2, pd);
    if cur_frame==0
        Screen('FillOval', screen.w, screen.white, pd);
    end
    cur_frame = cur_frame + 1;
    % Flip
    vbl = Screen('Flip', screen.w, vbl + (framesPerFlip-0.5)*screen.ifi );  
    % stop if key is pressed 
    if (KbCheck)
        stopFLAG=1; break; 
    end
end
log = addLog(log, 'duration', vbl-vbl0);
KbQueueFlush();
end

function [outer_rect, inner_rect] = annulusRect(radius, annulusWidth, screen, centerX, centerY)
    outer_radius = radius + annulusWidth/2.;
    inner_radius = radius - annulusWidth/2.;
    
    outer_rect = RectForScreen(screen, 2*outer_radius, 2*outer_radius, centerX, centerY);
    inner_rect = RectForScreen(screen, 2*inner_radius, 2*inner_radius, centerX, centerY);
end

function p =  AnnulusParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.
    addParamValue(p,'centerX', 0, @(x) isnumeric(x));
    addParamValue(p,'centerY', 0, @(x) isnumeric(x));
    addParamValue(p,'radius', 100, @(x) isnumeric(x));
    addParamValue(p,'AnnulusWidth', 10, @(x) x>0);
    addParamValue(p,'annColor', 128, @(x) x>0);
    addParamValue(p,'bgColor', 0, @(x) x>0);
end


function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    % In order to get a parameter back just use
    %   p.Resulst.parameter
    % In order to display all the parameters use
    %   disp 'List of all arguments:'
    %   disp(p.Results)
    %
    % General format to add inputs is...
    % p.addRequired('script', @ischar);
    % p.addOptional('format', 'html', ...
    %     @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
    % p.addParamValue('outputDir', pwd, @ischar);
    % p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);

    p  = inputParser;   % Create an instance of the inputParser class.

    addParamValue(p,'centerX', 0, @(x) isnumeric(x));
    addParamValue(p,'centerY', 0, @(x) isnumeric(x));
    addParamValue(p,'radius', 2000, @(x) isnumeric(x)); % um
    addParamValue(p,'color', [0 1 0], @(x) isnumeric(x)); % um
    addParamValue(p,'rotationAngle', 0, @(x) x>=0 && x <=360);
    addParamValue(p,'objContrast', 1, @(x) x>=0 && x <=1);
    addParamValue(p,'centerDot', 'Yes', @(x) ischar(x));
    % 
    addParamValue(p,'DurationSecs', 2, @(x)x>0);
    addParamValue(p,'Ncycle', 20, @(x)x>0);
    addParamValue(p,'halfPeriodSecs', 2, @(x)x>0);
    %
    addParamValue(p,'seed', 1, @(x) isnumeric(x));
    addParamValue(p,'debugging', 0, @(x) x>=0 && x <=1);
    addParamValue(p,'log', [], @(x) ischar(x));
    %
    %addParamValue(p,'stimFrameInterval', 0.033, @(x)x>=0);
    addParamValue(p,'stimFrameInterval', 0.0167, @(x)x>=0);
    %
    addParamValue(p,'array_type', 'HiDens_v3', @(x) ischar(x));   % in what units?
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
end

