function OMS_jitter_color_mask(varargin)
% Derived from function DriftDemo5(angle, cyclespersecond, f, drawmask)
% (4/1/09 mk Adapted from Allen Ingling's DriftDemo.m)
% 
% Global/differential jitter for probing OMS
% 1 repeat: global & differential motions with identical jitter sequence in
% center
% Color mask for choosing limiting color channels.
% jitter = randomly drawn from normal distribution. sometimes 3 px movement.

% 01/29/2018 (JK) Center sequence is repeated. Bg sequence will be identical during global motion
% 01/29/2018 (JK) Color independent jittering
% 01/30/2018 (JK) Flag for identical/random repeats for sessions
% 01/30/2018 (JK) Variance param for jitter statistics.
% 01/31/2018 (JK) ex struct
% 01/31/2018 (JK) color sync option

addpath('HelperFunctions/');
commandwindow % Change focus to command window
drawmask_BG=0; % if it is 0, BG would become square. 
%
HalfPeriod = 60; % um; (~RF size of BP)
StimSize_Ct = 600; % um
StimSize_BG = 1.2; % mm

% jitter parameters
% Max speed?
var = 0.5; % variance of the jitters or FEM (in pixels). Normal dist.
weight_Ct_step = 1; % 1 means 1 px
weight_Bg_step = 1;
waitframes = 1;
angleBG = 0;
%
pd_shift = 2.5; % mm
COLOR_MUTE_2 = false;
COLOR_MUTE_3 = false;

p = ParseInput(varargin{:});
seq_duration = p.Results.sDuration;
RANDOM_REPEAT = p.Results.random_repeat;
N_repeats = p.Results.N_repeats;
seed = p.Results.seed;
c_mask = p.Results.color_Mask;
sync_ch = p.Results.sync_to_ch;
FLAG_BG_TEXTURE = p.Results.background; 
c_intensity = p.Results.c_intensity;

w_grating = Pixel_for_Micron(HalfPeriod);
w_Annulus = Pixel_for_Micron(HalfPeriod);
TexBgSize_Half = Pixel_for_Micron(StimSize_BG*1000/2.); % Half-Size of the Backgr grating 
TexCtSize_Half = Pixel_for_Micron(StimSize_Ct/2.); % Half-Size of the Center grating
f=1/Pixel_for_Micron(2*HalfPeriod); % spatial frequency in px

try
    screen = InitScreen(0, 'bg_color', [0 0 0]);
    white = round(screen.white * c_intensity);
    black = screen.black;
    gray = round((white+black)/2.);
    w = screen.w;

    % Calculate parameters of the grating:
    p = ceil(1/f); % pixels/one cycle (= wavelength), rounded up.~2*Bipolar cell RF
    fr = f*2*pi;   % pahse per one pixel
    
    BG_visiblesize=2*TexBgSize_Half+1;
    Ct_visiblesize=2*TexCtSize_Half+1; % center texture size?

    % Create one single static grating image:
    % Grating pattern: Actual pixel numbers are needed for jitter
    % resolution. 
    m = grating_generator_1row(w_grating, (BG_visiblesize+3*w_grating));
    grating_BG = max(min(m*2*screen.gray, 255), 0);   
    m = grating_generator_1row(w_grating, (Ct_visiblesize+3*w_grating));
    grating_Ct = max(min(m*2*screen.gray, 255), 0);   

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
    ex.ifi = ifi;
    
    % Recompute p, this time without the ceil() operation from above.
    % Otherwise we will get wrong drift speed due to rounding!
    p=1/f; % pixels/cycle
    p=2*w_grating;
    
    %
    [pd, pd_color_max] = DefinePD_shift(w, 'shift', pd_shift*1000);
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
        
    seq_framesN = round(seq_duration/(waitframes*ifi)); % Num of frames for one session
    tot_framesN = seq_framesN * N_repeats; 
    
    % Get a random sequence representing FEM (Fixational Eye Movement)
    S1 = RandStream('mcg16807', 'Seed', seed);
    FEM_Ct = randi(S1, 3, tot_framesN, 3)-2;
    FEM_Ct = round(randn(S1, tot_framesN, 3)*var); % variance = 1; up to 3 color channels.
    FEM_Bg = circshift(FEM_Ct, round(tot_framesN/2.));
    
    % Identity matrix for color channel selection.
    c_array = eye(3);
    %
    xoffset_Bg = zeros(1,3); xoffset_Ct = zeros(1,3); 
    angleCenter = 0; secsPrev = 0; 
 
    vbl=0;
    %

    for i=1:2*N_repeats 
        
        % Global-Diff-Global-Diff- ...
        FLAG_Global_Motion = rem(i,2);
        
        % photodiode at the first frame of the sequence
        % disable alpha-blending, but allow updates of red channel only. 
        Screen('Blendfunction', w, GL_ONE, GL_ZERO, [1 0 0 1]);
        if FLAG_Global_Motion
                    Screen('FillOval', w, min(pd_color_max, 255), pd);
                    Screen('DrawText', w, 'Global Motion', 0.3*screen.sizeX, 0.8*screen.sizeY);
                    fprintf('(OMS jitter - global) session %d/%d (global)\n', i, 2*N_repeats);
        else
                    Screen('FillOval', w, min(pd_color_max, 255)/2., pd);
                    Screen('DrawText', w, 'Diff Motion', 0.3*screen.sizeX, 0.8*screen.sizeY);
                    fprintf('(OMS jitter - Diff) session %d/%d (diff)\n', i, 2*N_repeats);
        end
        % disable alph-blending, turn on color mask
        Screen('Blendfunction', w, GL_ONE, GL_ZERO, [c_mask 1]);
        
        if RANDOM_REPEAT
            cur_frame = 1 + seq_framesN * floor((i-1)/2); % Increase framesN by every 2 sessions. 
        else 
            cur_frame = 1;
        end
        end_frame = cur_frame + seq_framesN - 1;
        
        
        while (cur_frame <= end_frame)
                        
            for c = find(c_mask) % draw independently jittered color grating
                
                if COLOR_MUTE_2
                    if c == 2; continue; end;
                end
                if COLOR_MUTE_3
                    if c == 3; continue; end;
                end
                
                c_channel = c_array(c,:);
                Screen('Blendfunction', w, GL_ONE, GL_ZERO, [c_channel 1]);
                                
                % Jitter for each color channels
                xoffset_Bg(c) = mod( xoffset_Bg(c) + FEM_Bg(cur_frame,c)*weight_Bg_step, p);
                xoffset_Ct(c) = mod( xoffset_Ct(c) + FEM_Ct(cur_frame,c)*weight_Ct_step, p);

                if FLAG_Global_Motion
                    xoffset_Bg(c)  = xoffset_Ct(c);
                end

                % scrRect: 'jittered' subpart of the texture
                if sync_ch
                    srcRect=[xoffset_Bg(sync_ch) 0 xoffset_Bg(sync_ch) + BG_visiblesize BG_visiblesize];
                    src2Rect=[xoffset_Ct(sync_ch) 0 xoffset_Ct(sync_ch) + Ct_visiblesize Ct_visiblesize]; 
                else
                    srcRect=[xoffset_Bg(c) 0 xoffset_Bg(c) + BG_visiblesize BG_visiblesize];
                    src2Rect=[xoffset_Ct(c) 0 xoffset_Ct(c) + Ct_visiblesize Ct_visiblesize];
                end

                % Draw grating texture
                if FLAG_BG_TEXTURE
                    Screen('DrawTexture', w, gratingtexBg, srcRect, dstRect, angleBG);
                end

                if drawmask_BG
                    % Draw aperture (Oval) over grating:
                    %Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % Juyoung add
                    %Screen('Blendfunction', w, GL_ONE, GL_ZERO, [0 0 0 1]);
                    Screen('DrawTexture', w, masktex, [0 0 BG_visiblesize BG_visiblesize], dstRect, angleBG);
                end

                % annulus 
                Screen('FillOval', w, gray, rectAnnul);

                % Disable alpha-blending, restrict following drawing to alpha channel:
                Screen('Blendfunction', w, GL_ONE, GL_ZERO, [0 0 0 1]);
                % Clear 'dstRect' region of framebuffers alpha channel to zero: 
                Screen('FillRect', w, [0 0 0 0], dst2Rect); % Alpha 0 means completely clear. 
                % Fill circular 'dstRect' region with an alpha value of 255:
                Screen('FillOval', w, [0 0 0 255], dst2Rect);

                % Enable "DeSTination alpha blending" and reenable drawing to all
                % color channels. Following drawing commands will only draw there
                % the alpha value in the framebuffer is greater than zero, ie., in
                % our case, inside the circular 'dst2Rect' aperture where alpha has
                % been set to 255 by our 'FillOval' command:
                % Screen('Blendfunction', windowindex, [souce or new], [dest or
                % old], [colorMaskNew])
                % Juyoung comment: Why blending on? need to combine with the
                % predefined mask in alpha channel. Use destination alpha - 255 at the center. 0 outside of the center. 
                Screen('Blendfunction', w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [c_channel 1]);

                % Draw 2nd grating texture, but only inside alpha == 255 circular
                % aperture, and at an angle of 90 degrees: Now the angle is 0
                Screen('DrawTexture', w, gratingtexCt, src2Rect, dst2Rect, angleCenter);

                % Restore alpha blending mode for next draw iteration:??
                Screen('Blendfunction', w, GL_ONE, GL_ZERO, [c_channel 1]);
            end 
            
            % Flip 'waitframes' monitor refresh intervals after last redraw.
            [vbl, ~, ~, missed] = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            if (missed > 0)
                % A negative value means that dead- lines have been satisfied.
                % Positive values indicate a deadline-miss.
                if (cur_frame > 1) || (i > 1)
                    fprintf('(OMS jitter) session %d: cur_frame = %d, (flip) missed = %f\n', i, cur_frame, missed);
                end
            end
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
%                     case KbName('RightArrow')
%                         disp('Right Arrow pressed');
%                         angleBG = angleBG + 45;
%                     case KbName('LeftArrow')
%                         disp('Left Arrow pressed');
%                         angleBG = angleBG - 45;
%                     case KbName('9(') % default setting
%                         angleBG = angleBG + 90;    
%                     case KbName('0)') % default setting
%                         angleBG = 0;
                    case KbName('.>')
                        
                    case KbName(',<')
                        
                    case KbName('2@')
                        COLOR_MUTE_2 = ~COLOR_MUTE_2
                    case KbName('3#')
                        COLOR_MUTE_3 = ~COLOR_MUTE_3
%                     case KbName('space')
%                         FLAG_Global_Motion = ~FLAG_Global_Motion;
%                         
%                     case KbName('UpArrow') 
% 
%                     case KbName('DownArrow')
% 
%                     case KbName('DELETE')
%                         FLAG_BG_TEXTURE = ~FLAG_BG_TEXTURE;
                    otherwise                    
                end
                secsPrev = secs;
            end             

        end; % WHILE end
    
        if keyIsDown && (key == KbName('ESCAPE'))
            break;
        end
        % exp parameter update
        
    end % for loop
    
    % ex struct
    str = datestr(datetime('now'), 'yyyymmdd_HHMMSS');
    assignin(ws, ['ex_jitter_',str], ex);
    
    
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
    addParamValue(p,'random_repeat', true, @(x) islogical(x));
    addParamValue(p,'color_Mask', [0 1 1], @(x) isnumeric(x));
    addParamValue(p,'seed', 1, @(x) isnumeric(x));
    addParamValue(p,'sync_to_ch', 2, @(x) isnumeric(x));
    addParamValue(p,'background', true, @(x) islogical(x));
    addParamValue(p,'c_intensity', 1, @(x) isnumeric(x));
     
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

