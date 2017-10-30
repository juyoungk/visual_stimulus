function OMS_jitter(varargin)
% function DriftDemo5(angle, cyclespersecond, f, drawmask)
% ___________________________________________________________________
%
% Display animated gratings using the new Screen('DrawTexture') command.
%
% The demo shows two drifting sine gratings through circular apertures. The
% 1st drifting grating is surrounded by an annulus (a ring) that shows a
% second drifting grating with a different orientation.
%
% The demo ends after a key press or after 20 seconds have elapsed.
%
% The demo uses alpha-blending and color buffer masking for masking the
% gratings with circular apertures.
%
% Parameters:
%
% angle = Angle of the grating with respect to the vertical direction.
% cyclespersecond = Speed of grating in cycles per second. f = Frequency of
% grating in cycles per pixel.
% drawmask = If set to 1, then an aperture is drawn over the grating
% _________________________________________________________________________
%
% see also: PsychDemos, MovieDemo

% HISTORY
% 4/1/09 mk Adapted from Allen Ingling's DriftDemo.m

commandwindow % Change focus to command window
drawmask_BG=1; % if it is 0, BG would become square. 

p = ParseInput(varargin{:});
%
seq_duration = p.Results.sDuration;
N_repeats = p.Results.N_repeats;
seed = p.Results.seed;

FLAG_Global_Motion = 1;
    
waitframes = 1;
weight_Ct_step = 1; % 1 means 1 px
weight_Bg_step = 1;
angleBG = 0;
%
HalfPeriod = 60; % um; (~RF size of BP)
StimSize_Ct = 550; % um
StimSize_BG = 2.4; % mm

% 2 means 30 Hz stimulus with 60 Hz monitor
%
w_Annulus = Pixel_for_Micron(HalfPeriod);
TexBgSize_Half = Pixel_for_Micron(StimSize_BG*1000/2.); % Half-Size of the Backgr grating 
TexCtSize_Half = Pixel_for_Micron(StimSize_Ct/2.); % Half-Size of the Center grating
f=1/Pixel_for_Micron(2*HalfPeriod);

try
    screen = InitScreen(0, 'bg_color', [0 0 0]);
    white = screen.white;
    black = screen.black;
    gray = screen.gray;
    inc=white-gray;
    w = screen.w;
    ifi = screen.ifi;
    
%     AssertOpenGL; 
%     
%     % Get the list of screens and choose the one with the highest screen number.
%     screenNumber=max(Screen('Screens'));
%     % Find the color values which correspond to white and black.
%     white=WhiteIndex(screenNumber);
%     black=BlackIndex(screenNumber);

%     % Open a double buffered fullscreen window with a gray background:
%     rate = Screen('NominalFrameRate', screenNumber);
%     if rate == 0
%         Screen('Preference', 'SkipSyncTests',1);
%         [w, screenRect]=Screen('OpenWindow',screenNumber, gray, [10 10 1010 1160]);
%         oldtxtsize = Screen('TextSize', w, 17);
%     else
%         Screen('Resolution', screenNumber, 800, 600, 60);
%         [w, screenRect]=Screen('OpenWindow',screenNumber, gray);
%         oldtxtsize = Screen('TextSize', w, 9);
%         HideCursor(screenNumber);
%     end

    % Calculate parameters of the grating:
    p = ceil(1/f) % pixels/one cycle (= wavelength), rounded up.~2*Bipolar cell RF
    fr = f*2*pi;   % pahse per one pixel
    BG_visiblesize=2*TexBgSize_Half+1;
    Ct_visiblesize=2*TexCtSize_Half+1; % center texture size?

    % Create one single static grating image:
    % MK: We only need a single texture row (i.e. 1 pixel in height) to
    % define the whole grating! If srcRect in the Drawtexture call below is
    % "higher" than that (i.e. visibleSize >> 1), the GPU will
    % automatically replicate pixel rows. This 1 pixel height saves memory
    % and memory bandwith, ie. potentially faster.
    %
    % texture size? visible size + one more cycle (p; pixels per cycle)
    [x ,~]=meshgrid(-TexBgSize_Half:TexBgSize_Half + p, 1);
    %[x ,~]=meshgrid(1:BG_visiblesize + p, 1);
    % inc = white-gray ~ contrast : Grating
    grating_BG = gray + inc*cos(fr *x );   
    %grating_BG = max(min(mod(x,2)*2*screen.gray, 255), 0);   

    [x2,~]=meshgrid(-TexCtSize_Half:TexCtSize_Half + p, 1);
    %[x2,~]=meshgrid(1:Ct_visiblesize + p, 1);
    grating_Ct = gray + inc*cos(fr *x2);
    %grating_Ct = max(min(mod(x2,2)*2*screen.gray, 255), 0);

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

    % Definition of the drawn rectangle on the screen:
%     dstRect=[0 0 visiblesize visiblesize];
%     dstRect=CenterRect(dstRect, screenRect);
    dstRect=CenterRect([0 0 BG_visiblesize BG_visiblesize], screen.rect);

    % Definition of the drawn rectangle on the screen:
%     dst2Rect=[0 0 visible2size visible2size]; % half size rect.
%     dst2Rect=CenterRect(dst2Rect, screenRect);    
    dst2Rect=CenterRect([0 0 Ct_visiblesize Ct_visiblesize], screen.rect);
    
    % Annulus for boundary between center and BG
    rectAnnul = CenterRect([0 0 Ct_visiblesize+2*w_Annulus Ct_visiblesize+2*w_Annulus], screen.rect);

    % Query duration of monitor refresh interval:
    ifi=Screen('GetFlipInterval', w)

    % Recompute p, this time without the ceil() operation from above.
    % Otherwise we will get wrong drift speed due to rounding!
    p=1/f; % pixels/cycle
    %
    
    [pd, pd_color_max] = DefinePD_shift(w);
    Screen('FillOval', w, black, pd); % first PD: black
    % background: black
    Screen('FillRect', w, screen.bg_color);
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    vbl=Screen('Flip', w);
    %
    WaitStartKey(w, 'expName', 'OMS jitter');
    device_id = MyKbQueueInit; % paired with "KbQueueFlush()"
    % We run at most 'movieDurationSecs' seconds if user doesn't abort via
    % keypress.
        
    seq_framesN = round(seq_duration/(waitframes*ifi)); % Num of frames over one step period = Num of phases
    % initial sequence of center(object) 
    
    % Get a random sequence representing FEM (Fixational Eye Movement)
    S1 = RandStream('mcg16807', 'Seed', seed);
    FEM_Ct = randi(S1, 3, seq_framesN, 1)-2;
    FEM_Bg = circshift(FEM_Ct, round(seq_framesN/2.));  
    
%     if ~FLAG_Global_Motion
%         FEM_Bg = circshift(FEM_Ct, double(seq_framesN/2));
%     else
%         FEM_Bg = FEM_Ct;
%     end  
    xoffset_Bg = 0; xoffset_Ct = 0; angleCenter = 0; secsPrev = 0; 
    FLAG_BG_TEXTURE = 1; 
    FLAG_debug = 0;
    %
    %
    for i=1:2*N_repeats 
        
        % Global-Diff-Global-Diff- ...
        FLAG_Global_Motion = rem(i,2);
        
        % photodiode at the first frame of the sequence
        %Screen('Blendfunction', w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
        %Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, [1 1 1 1]); % red channel only
        
        if mod(i ,2) == 1
                    Screen('FillOval', w, pd_color_max, pd);
        else
                    Screen('FillOval', w, pd_color_max/2., pd);
        end
        
        cur_frame = 0;
        
        while (cur_frame < seq_framesN)
            % Jitter by Juyoung: 
            % Generate random integer [-1, 0, 1] ~ 1 pixel deviation?
            xoffset_Bg = mod( xoffset_Bg + FEM_Bg(cur_frame+1)*weight_Bg_step, p);
            xoffset_Ct = mod( xoffset_Ct + FEM_Ct(cur_frame+1)*weight_Ct_step, p);
 
            if FLAG_Global_Motion
                xoffset_Ct = xoffset_Bg;
            end

            % Jittered scrRect: subpart of the texture
            srcRect=[xoffset_Bg 0 xoffset_Bg + BG_visiblesize BG_visiblesize];
            src2Rect=[xoffset_Ct 0 xoffset_Ct + Ct_visiblesize Ct_visiblesize];

            % Draw grating texture, rotated by "angle":
            if FLAG_BG_TEXTURE
                Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, [0 1 0 1]); % gree (or UV) channel only
                Screen('DrawTexture', w, gratingtexBg, srcRect, dstRect, angleBG);
                %Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            end

            if drawmask_BG==1
                % Draw aperture (Oval) over grating:
                Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % Juyoung add
                Screen('DrawTexture', w, masktex, [0 0 BG_visiblesize BG_visiblesize], dstRect, angleBG);
            end;

            % annulus 
            Screen('FillOval', w, gray, rectAnnul);
            % pd
            if cur_frame == 0
                if mod(i ,2) == 1
                    Screen('FillOval', w, pd_color_max, pd);
                else
                    Screen('FillOval', w, pd_color_max/2., pd);
                end
            end
            

            % Disable alpha-blending, restrict following drawing to alpha channel:
            Screen('Blendfunction', w, GL_ONE, GL_ZERO, [0 0 0 1]);
            % Clear 'dstRect' region of framebuffers alpha channel to zero:
            Screen('FillRect', w, [0 0 0 0], dst2Rect);
            % Fill circular 'dstRect' region with an alpha value of 255:
            Screen('FillOval', w, [0 0 0 255], dst2Rect);

            % Enable "DeSTination alpha blending" and reenable drawing to all
            % color channels. Following drawing commands will only draw there
            % the alpha value in the framebuffer is greater than zero, ie., in
            % our case, inside the circular 'dst2Rect' aperture where alpha has
            % been set to 255 by our 'FillOval' command:
            % Screen('Blendfunction', windowindex, [souce or new], [dest or
            % old], [colorMaskNew])
            %Screen('Blendfunction', w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
            Screen('Blendfunction', w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [0 1 0 1]); %green(UV LED) channel only

            % Draw 2nd grating texture, but only inside alpha == 255 circular
            % aperture, and at an angle of 90 degrees: Now the angle is 0
            Screen('DrawTexture', w, gratingtexCt, src2Rect, dst2Rect, angleCenter);

            % Restore alpha blending mode for next draw iteration:
            Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
            
            % pd
            if cur_frame == 0
                if mod(i ,2) == 1
                    Screen('FillOval', w, pd_color_max, pd);
                else
                    Screen('FillOval', w, pd_color_max/2., pd);
                end
            end
        

            % Flip 'waitframes' monitor refresh intervals after last redraw.
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            cur_frame = cur_frame + 1;
   
            %
            [keyIsDown, firstPress] = KbQueueCheck();
            if keyIsDown
                key = find(firstPress);
                secs = min(firstPress(key)); % time for the first pressed key
                if (secs - secsPrev) < 0.1
                    continue
                end

                switch key
                    case KbName('ESCAPE')
                        break;
                    case KbName('q')
                        break;
                    case KbName('j') % jitter
                        %FLAG_SimpleMove = 0;
                    case KbName('RightArrow')
                        disp('Right Arrow pressed');
                        angleBG = angleBG + 45;
                    case KbName('LeftArrow')
                        disp('Left Arrow pressed');
                        angleBG = angleBG - 45;
                    case KbName('9(') % default setting
                        angleBG = angleBG + 90;    
                    case KbName('0)') % default setting
                        angleBG = 0;
                    case KbName('.>')
                        
                    case KbName(',<')
                        
                    case KbName('space')
                        FLAG_Global_Motion = ~FLAG_Global_Motion;
                        %bg_phase_delay = (~bg_phase_delay)*round(N_phase/2);
                    case KbName('UpArrow') 

                    case KbName('DownArrow')

                    case KbName('DELETE')
                        FLAG_BG_TEXTURE = ~FLAG_BG_TEXTURE;

                    case KbName('d') % debug mode
                        FLAG_debug = 1;

                    otherwise                    
                end
                secsPrev = secs;
            end             

        end; % WHILE end
    
        if keyIsDown && (key == KbName('ESCAPE'))
            break;
        end
        % exp parameter update
        
        %
    end % for loop
    
    % black screen
    Screen('FillRect', w, 0);
    Screen('Flip', w, 0);
    % pause until Keyboard pressed
    KbWait(-1, 2); 
    
    %KbQueueFlush(device_id(1));
    KbQueueStop(device_id(1));
    Priority(0);
    Screen('CloseAll'); % same as "sca"
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
    %KbQueueFlush(device_id(1));
    KbQueueStop(device_id(1));
end %try..catch..

end

function p =  ParseInput(varargin)
    
    p  = inputParser;   % Create an instance of the inputParser class.
    
    addParamValue(p,'sDuration', 10, @(x)x>=0);
    addParamValue(p,'N_repeats', 3, @(x)x>=0);
    addParamValue(p,'seed', 1, @(x) isnumeric(x));
     
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

