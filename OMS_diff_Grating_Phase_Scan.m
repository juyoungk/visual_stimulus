function OMS_diff_Grating_Phase_Scan
% one grating at the center, the other grating at the background
% test the effect of delayed motion between center and the BG.
%
% Modified from DriftDemo5(angle, cyclespersecond, f, drawmask)
% Modified from OMS_SimpleMove
commandwindow % Change focus to command window
%
StimSize_Ct = 750; % um
StimSize_BG = 2.4; % mm
BarWidth = 100; % um; Grating Bar; Half the period; ~RF size of BP
w_Annulus = BarWidth;
%
    waitframes = 1;   % 1 means 60 Hz refresh rate ~ 16.6 ms
delay_interval = 2;   % stimulus frames for delay interval.
maxDelay = 180; % ms
% parameters for periodic move (constant speed)
shift_Ct = 0.5; % 1 is shift of 1 bar width
shift_Bg = 0.5; 
shift_speed = 1000; % um/s
period_Secs = 1; % secs
  N_periods = 8; % periods of steps
% parameters for recovery stage
period_Secs_recovery = 1; % secs
N_periods_recovery  = 8; % periods of steps
% Angles of gratings
angleCenter = 0; 
%angleBG = 0;
angleBG = [0];
%angleBG = linspace(45,360,8);

%
w_Annulus = Pixel_for_Micron(w_Annulus);
TexBgSize_Half = Pixel_for_Micron(StimSize_BG*1000/2.); % Half-Size of the Backgr grating 
TexCtSize_Half = Pixel_for_Micron(StimSize_Ct/2.); % Half-Size of the Center grating
barWidthPixels = Pixel_for_Micron(BarWidth);
p = 2*barWidthPixels; % pixels/one cycle (= wavelength) ~2*Bipolar cell RF
f = 1./p;    % Grating cycles/pixel; spatial phase velocity
fr=f*2*pi;   % pahse per one pixel
speed = Pixel_for_Micron(shift_speed);

%
try
    AssertOpenGL;
    
    % Get the list of screens and choose the one with the highest screen number.
    screenNumber=max(Screen('Screens'))
    % Find the color values which correspond to white and black.
    white=WhiteIndex(screenNumber);
    black=BlackIndex(screenNumber);
    
    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
    gray=round((white+black)/2);
    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if gray == white
      gray=white / 2;
    end
    inc=white-gray;

    % Open a double buffered fullscreen window with a gray background:
    rate = Screen('NominalFrameRate', screenNumber);
    if rate == 0
        Screen('Preference', 'SkipSyncTests',1);
        [w, screenRect]=Screen('OpenWindow',screenNumber, gray, [10 10 1010 1160]);
        oldtxtsize = Screen('TextSize', w, 17);
    else
        Screen('Resolution', screenNumber, 800, 600, 60);
        [w, screenRect]=Screen('OpenWindow',screenNumber, gray);
        oldtxtsize = Screen('TextSize', w, 9);
        HideCursor(screenNumber);
    end
    % Query duration of monitor refresh interval:
    ifi=Screen('GetFlipInterval', w)
    
    % Calculate parameters of the grating:
    BG_visiblesize=2*TexBgSize_Half+1;
    Ct_visiblesize=2*TexCtSize_Half+1; % center texture size?

    % Create one single static grating image:
    % MK: We only need a single texture row (i.e. 1 pixel in height) to
    % define the whole grating! If srcRect in the Drawtexture call below is
    % "higher" than that (i.e. visibleSize >> 1), the GPU will
    % automatically replicate pixel rows.
    %
    % texture size? visible size + one more cycle (p; pixels per cycle)
    [x ,~]=meshgrid(-TexBgSize_Half:TexBgSize_Half + p, 1);
    % inc = white-gray ~ contrast : Grating
    grating_BG = gray + inc*cos(fr *x );   

    [x2,~]=meshgrid(-TexCtSize_Half:TexCtSize_Half + p, 1);
    grating_Ct = gray + inc*cos(fr *x2);

    % Store grating in texture:
    gratingtexBg = Screen('MakeTexture', w, grating_BG);
    gratingtexCt = Screen('MakeTexture', w, grating_Ct);

    % Create a single binary transparency mask and store it to a texture:
    % Why 2 layers? LA (Luminance + Alpha)
    mask=ones(2*TexBgSize_Half+1, 2*TexBgSize_Half+1, 2) * gray;
    [x,y]=meshgrid(-1*TexBgSize_Half:1*TexBgSize_Half,-1*TexBgSize_Half:1*TexBgSize_Half);
    % Gaussian profile can be introduced at the 1st Luminance layer.
    % Apeture ratidus for alpha 255 (opaque) = TexBgSize_Half (2nd layer)
    mask(:, :, 2) = white * (1-(x.^2 + y.^2 <= TexBgSize_Half^2));
    masktex=Screen('MakeTexture', w, mask);

    % Recompute p, this time without the ceil() operation from above.
    % Otherwise we will get wrong drift speed due to rounding!
   
    %
    % initial sequence of center(object) 
    phase_init_ct = 0;
    % phase delay setting
    id_maxDelay = ceil(maxDelay*0.001/(ifi*waitframes*delay_interval));
    delays_Ct_Bg = (-id_maxDelay:id_maxDelay)*delay_interval;
    delays_Ct_Bg = fliplr(delays_Ct_Bg);
    %
    
    WaitStartKey(w, 'expName', 'Differential step stimulus for OMS');
    device_id = MyKbQueueInit; % paired with "KbQueueFlush()"
    %
    vbl=0;
    %
    for j=1:numel(angleBG)    
    for i=1:numel(delays_Ct_Bg) % between object and background
        
         phase_txt = ['[ ',num2str(i),'/', num2str(numel(delays_Ct_Bg)), ' phase ] '];
        % recovery from depression or make circuit same condition: 
        % Global motion (10s)
        vbl = diff_Grating_Screen(vbl, w, screenRect, waitframes, ifi, white, black, ...
           BG_visiblesize, Ct_visiblesize, gratingtexBg, gratingtexCt, masktex, ...
           barWidthPixels, shift_Ct, shift_Bg, speed, ...
           phase_init_ct, 0, ... % shift for center and BG.
           period_Secs_recovery, N_periods_recovery, ...
           0, angleCenter, w_Annulus, gray, ... % angleBG = 0 for recovery stage
           [phase_txt, '(1) recovery periods (global motion)']); 
     
       
        % stimulus: phase delay
        vbl = diff_Grating_Screen(vbl, w, screenRect, waitframes, ifi, white, black, ...
           BG_visiblesize, Ct_visiblesize, gratingtexBg, gratingtexCt, masktex, ...
           barWidthPixels, shift_Ct, shift_Bg, speed, ...
           phase_init_ct, delays_Ct_Bg(i), ... % shift for center and BG.
           period_Secs, N_periods, ...
           angleBG(j), angleCenter, w_Annulus, gray, ...
           [phase_txt, '(2) shifts of gratings with delays']);
        
       % phase condition update
       %bg_phase_delay = bg_phase_delay + phase_inc;
    
    end % for loop
    end
    %KbQueueFlush(device_id(1));
    KbQueueStop(device_id(1));
    
    % gray screen
    Screen('FillRect', w, gray/4);
    Screen('Flip', w, 0);
    % pause until Keyboard pressed
    KbWait(-1, 2); 
    
    %
    Screen('CloseAll'); % same as "sca"
    Priority(0);
    ShowCursor();
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
    KbQueueFlush(device_id(1));
    KbQueueStop(device_id(1));
    ShowCursor();
end %try..catch..


end