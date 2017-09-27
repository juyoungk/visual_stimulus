function testscreen(debug, modulateColor)

if nargin == 0 
    debug =1;
    modulateColor =[255 255 255];
elseif nargin == 1
    modulateColor =[255 255 255];
end

color_sequence = { modulateColor,
                   [255, 0, 0], 
                   [0, 255, 0], 
                   [0, 0, 255] };
n_colors = length(color_sequence);
               
commandwindow
addpath('HelperFunctions/')

screen = InitScreen(debug);
waitframes = 1;

    boxL_um = 60; %unit: um
        bar_width = 3; % # boxes.
    boxL = Pixel_for_Micron(boxL_um);  %um to pixels %not good to round here.
    disp(['Pixel N for ', num2str(boxL_um), 'um =  ', num2str(boxL), ' px']);
    disp(['Pixel N for ', num2str(100), 'um =  ', num2str(PIXELS_PER_100_MICRONS), ' px']);
    
    % MEA Box (150um = MEA length = 30 * 5)
    boxL_mea = 10*boxL;
    
    N = 36; % determines the stim size
    stimsize = N*boxL;
    disp(['Stim size = ', num2str(N*boxL_um), ' um (', num2str(stimsize), ' px)']);

 % Define the obj Destination Rectangle
objRect = RectForScreen(screen,stimsize,stimsize,0,0);

 for i=1:2
    % 1. random texture pointer
    %Screen('FillRect', screen.w, 0.5*modulateColor);
    %texMatrix = ( rand(N, N)>.5)*2*screen.gray;
    %objTex  = Screen('MakeTexture', screen.w, texMatrix);
    % display last texture
    %Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0, 1, modulateColor); % globalalpha default = 1, but ignored when modulateColor is specified.
    
    % 2. checker on gray
    % 
    [x, y] = meshgrid(1:N, 1:N);
    texMatrix = mod(x+y,2)*2*screen.gray;
    % texture pointer
    objTex  = Screen('MakeTexture', screen.w, texMatrix);
    for j=1:n_colors
        Screen('FillRect', screen.w, 0.5*modulateColor);
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0, 1, color_sequence{j});
        Screen('FillOval', screen.w, screen.white, DefinePD);
         %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect]
        %[,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [,
        %modulateColor] [, textureShader] [, specialFlags] [, auxParameters]);
        Screen('Flip', screen.w, 0);
        KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
        if YorN==27, break; end;
    end
    
    % 3-0. Stim area (0 intensity outside of the stim area)
    box =  RectForScreen(screen,stimsize,stimsize,0, 0);
        % dark Stim area on gray       
        Screen('FillRect', screen.w, modulateColor);
        Screen('FillRect', screen.w, 0, box);
        Screen('Flip', screen.w, 0);
        KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
        if YorN==27, break; end
        
        % bright stim area on dark
 
        Screen('FillRect', screen.w, 0);
        Screen('FillRect', screen.w, modulateColor, box);
        Screen('Flip', screen.w, 0);
        KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
        if YorN==27, break; end
 
        
    % 3-1. MEA Box (0 intensity)
    
    % dark MEA on gray
    box =  RectForScreen(screen, boxL_mea, boxL_mea, 0, 0);
        Screen('FillRect', screen.w, 0.5*modulateColor); % background
        Screen('FillRect', screen.w, 0, box);
        Screen('Flip', screen.w, 0);
        KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
        if YorN==27, break; end;
    
        % white MEA on dark 
    % for power calibration
        Screen('FillRect', screen.w, 0); % background
        Screen('FillRect', screen.w, modulateColor, box);
        Screen('Flip', screen.w, 0);
        KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
        if YorN==27, break; end;
    

    % 3-2. 1 Box
    box =  RectForScreen(screen,boxL,boxL,0, 0);
        % dark box on gray
        Screen('FillRect', screen.w, 0.5*modulateColor);
        Screen('FillRect', screen.w, 0, box);
        Screen('Flip', screen.w, 0);
        KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
        if YorN==27, break; end;

        % bright box on dark
        Screen('FillRect', screen.w, 0);
        Screen('FillRect', screen.w, modulateColor, box);
        Screen('Flip', screen.w, 0);
        KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
        if YorN==27, break; end

    % black screen
    Screen('FillRect', screen.w, 0);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end
    
    % moving bar?
    % 2*N+1 texture with a bar at the center. Draw a subpart
    texMatrix = ones(N,2*N+1);
    texMatrix(:, N+1) = 0;
    objTex  = Screen('MakeTexture', screen.w, texMatrix);
    
    shiftperframe = 1;% in pixels 
    n_frames = round(stimsize/shiftperframe);
    
    for i = 1:n_frames
        % Shift the grating by "shiftperframe" pixels per frame:
        xoffset = mod(i*shiftperframe, N);
        % Define shifted srcRect that cuts out the properly shifted rectangular
        % area from the texture:
        %srcRect=[xoffset 0 xoffset + visiblesize visiblesize];
        
        Screen('FillRect', screen.w, 0.5*modulateColor);
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0, 1, modulateColor);
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        %vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * screen.ifi);
    end
    
    
end

Screen('CloseAll');

end