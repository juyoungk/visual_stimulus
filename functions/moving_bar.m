function moving_bar(varargin)
% Modified from DriftDemo3
%
% 2017 1001 Juyoung Kim
% 
commandwindow
p = ParseInput(varargin{:});
%
bar_width = p.Results.barWidth;
bar_speed = p.Results.barSpeed;
bar_color = p.Results.barColor;
N_repeats = p.Results.N_repeat;
c_mask = p.Results.c_mask;

% bar sweep size
visiblesize = 64;        % Size of the grating image. Needs to be a power of two.
%
bar_width = Pixel_for_Micron(bar_width);
speed_in_Pixels = Pixel_for_Micron(bar_speed*1000);

screen = InitScreen(0);
w = screen.w;
white = screen.white;
black = screen.black;
%         % This script calls Psychtoolbox commands available only in OpenGL-based 
%         % versions of the Psychtoolbox. The Psychtoolbox command AssertPsychOpenGL will issue
%         % an error message if someone tries to execute this script on a computer without
%         % an OpenGL Psychtoolbox.
%         AssertOpenGL;
% 
%         % Get the list of screens and choose the one with the highest screen number.
%         % Screen 0 is, by definition, the display with the menu bar. Often when 
%         % two monitors are connected the one without the menu bar is used as 
%         % the stimulus display.  Chosing the display with the highest dislay number is 
%         % a best guess about where you want the stimulus displayed.  
%         screens=Screen('Screens');
%         screenNumber=max(screens);
% 
%         % Find the color values which correspond to white and black: Usually
%         % black is always 0 and white 255, but this rule is not true if one of
%         % the high precision framebuffer modes is enabled via the
%         % PsychImaging() commmand, so we query the true values via the
%         % functions WhiteIndex and BlackIndex:
%         white=WhiteIndex(screenNumber)
%         black=BlackIndex(screenNumber);

%         % Open a double buffered fullscreen window and draw a gray background 
%         % to front and back buffers as background clear color:
%         [w, w_rect] = Screen('OpenWindow',screenNumber, gray);



% Round gray to integral number, to avoid roundoff artifacts with some
% graphics cards:
gray=round((white+black)/2);

% This makes sure that on floating point framebuffers we still get a
% well defined gray. It isn't strictly neccessary in this demo:
if gray == white
    gray=white / 2;
end

% Contrast 'inc'rement range for given white and gray values:
inc=white-gray;

% Create one single static 1-D grating image.
% We only need a texture with a single row of pixels(i.e. 1 pixel in height) to
% define the whole grating! If the 'srcRect' in the 'Drawtexture' call
% below is "higher" than that (i.e. visibleSize >> 1), the GPU will
% automatically replicate pixel rows. This 1 pixel height saves memory
% and memory bandwith, ie. it is potentially faster on some GPUs.

x = meshgrid(1:visiblesize, 1:visiblesize);
%white_bar = gray + inc*(x <= bar_width);
white_bar = white*(x <= bar_width);
dark_bar = gray*(x > bar_width);


% Store grating in texture: Set the 'enforcepot' flag to 1 to signal
% Psychtoolbox that we want a special scrollable power-of-two texture:

switch bar_color
    case 'white'
        bar = white_bar;
        %bartex=Screen('MakeTexture', w, white_bar, [], 1); % specialFlag =1 means size should be power of 2.
        bgtex = Screen('MakeTexture', w, black, [], 1);
    case 'dark'
        bar = dark_bar;
        %bartex=Screen('MakeTexture', w, dark_bar, [], 1);
        bgtex = Screen('MakeTexture', w, gray, [], 1);
    otherwise
end

% imgMat = zeros(visiblesize, visiblesize, 3);
% imgMat(:,:,2) = bar; 
% bartex=Screen('MakeTexture', w, imgMat, [], 1);

bartex=Screen('MakeTexture', w, bar, [], 1);


% Query duration of monitor refresh interval:
ifi=Screen('GetFlipInterval', w);
waitframes = 1; % max refreash rate
waitduration = waitframes * ifi;
%
shiftperframe= speed_in_Pixels * waitduration;

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
vbl=Screen('Flip', w);

% We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
%vblendtime = vbl + movieDurationSecs;
xoffset=0;
[pd, pd_color] = DefinePD_shift(w);

%
WaitStartKey(w, 'expName', ['Moving bar (', bar_color, ')']);

% first cycle
i_cycle = 1;
Screen('FillOval', w, pd_color, pd);

%
rot_angle=0;
inc_angle=90;

% Animationloop:
while(i_cycle <= N_repeats)   
   % Define shifted srcRect that cuts out the properly shifted rectangular
   % area from the texture:
   srcRect = [xoffset 0 xoffset + visiblesize visiblesize];
   dstRect = RectForScreen(screen, visiblesize, visiblesize, 0, 0);
   % Draw grating texture: Only show subarea 'srcRect', center texture in
   % the onscreen window automatically:
   %Screen('DrawTexture', w, gratingtex, srcRect);
   Screen('Blendfunction', w, GL_ONE, GL_ZERO, [c_mask 1]);
   Screen('DrawTexture', w, bartex, srcRect, dstRect, rot_angle);
   
   % Flip 'waitframes' monitor refresh intervals after last redraw.
   [vbl, ~, ~, missed] = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
    if (missed > 0)
        % A negative value means that dead- lines have been satisfied.
        % Positive values indicate a deadline-miss.
        if (xoffset < 0) || (i_cycle > 1)
            fprintf('(Moving bar) repeat %d: offset = %f, (flip) missed = %f\n', i_cycle, xoffset, missed);
        end
    end

   % Abort demo if any key is pressed:
   if KbCheck
      break;
   end
   
   % Shift the grating by "shiftperframe" pixels per frame:
   xoffset = xoffset - shiftperframe;
   
   if xoffset < -(visiblesize-bar_width)
        % blank gray frame
        Screen('Blendfunction', w, GL_ONE, GL_ZERO, [c_mask 1]);
        Screen('DrawTexture', w, bgtex, srcRect, dstRect, rot_angle);
        vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
   
        % prepare next cycle    
        xoffset = 0; % set to same position
        rot_angle = rot_angle + inc_angle;
        
        % pd draw
        Screen('Blendfunction', w, GL_ONE, GL_ZERO, [1 0 0 1]);
        Screen('FillOval', w, pd_color, pd);

        i_cycle = i_cycle +1; % increase cycle number.
       
       pause(1);
   end
   
end

% The same commands wich close onscreen and offscreen windows also close
% textures.
sca;

end

function p =  ParseInput(varargin)
    
    p  = inputParser;   % Create an instance of the inputParser class.
    
    addParamValue(p,'N_repeat', 20, @(x)x>=0);
    addParamValue(p,'barWidth', 150, @(x)x>=0);
    addParamValue(p,'barSpeed', 1.4, @(x)x>=0);
    addParamValue(p,'c_channels', 2, @(x) ismatrix(x)); % index for color channesl. e.g. 2 or [2, 3]
    addParamValue(p,'c_mask', [0 1 1], @(x) isvector(x));
    addParamValue(p,'barColor', 'dark', @(x) strcmp(x,'dark') || ...
        strcmp(x,'white'));
     
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end



