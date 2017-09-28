function testscreen_colors(debug, intensity_factor)
% intensity calibration? max duty rate (= max intensity)
% scan intensity

if nargin == 0 
    debug =0;
    intensity_factor = 1;
elseif nargin == 1
    intensity_factor = 1;
end

color_sequence = { [255, 0, 0]* intensity_factor, 
                   [0, 255, 0]* intensity_factor, 
                   [0, 0, 255]* intensity_factor
                 };             
n_colors = length(color_sequence);
               
commandwindow;
addpath('HelperFunctions/')

screen = InitScreen(debug);
disp(['screen.white = ',num2str(screen.white)]);
disp(['screen.black = ',num2str(screen.black)]);

    boxL_um = 50; %unit: um
    boxL = Pixel_for_Micron(boxL_um);  %um to pixels
    
    N = 40; % determines the stim size
    stimsize = Pixel_for_Micron(boxL_um*N);
    
    disp(['Pixel N for ', num2str(boxL_um), 'um =  ', num2str(boxL), ' px']);
    disp(['Pixel N for ', num2str(100), 'um =  ', num2str(PIXELS_PER_100_MICRONS), ' px']);
    disp(['Pixel N for ', num2str(boxL_um*N), 'um =  ', num2str(stimsize), ' px']);
    

    % 3-2. MEA Box (150um = MEA length = 30 * 5)
    boxL_ref = 7*PIXELS_PER_100_MICRONS;
    
% Define the obj Destination Rectangle
objRect = RectForScreen(screen,stimsize,stimsize,0,0);

% Define PD
[windowSizeX, windowSizeY] = Screen('WindowSize', max(Screen('Screens')))
pd = SetRect(0,0, windowSizeY*.08, windowSizeY*.08);
pd = CenterRect(pd, screen.rect);
pd_shift = 1000 %from center. um.
x = Pixel_for_Micron(pd_shift);
pd = OffsetRect(pd, x, x);
%pd = CenterRectOnPoint(pd, windowSizeX*.65, windowSizeY*.45);

 for i=1:1
    % 1. Stim area (0 intensity outside of the stim area)
    box =  RectForScreen(screen,stimsize,stimsize, 0, 0);
    % color change @ white intensity
        for j=1:n_colors
            % bright stim area on dark
            Screen('FillRect', screen.w, 0);
            Screen('FillRect', screen.w, color_sequence{j}, box);
            Screen('Flip', screen.w, 0);
            KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
            if YorN==27, break; end
        end
    % 2. texture (Is there a chromatic abberation ?)
    [x, y] = meshgrid(1:N, 1:N);
    texMatrix = mod(x+y,2)*2*screen.gray;
    objTex  = Screen('MakeTexture', screen.w, texMatrix);
    % color change @ white intensity
        for j=1:n_colors
            % bright stim area on dark
            Screen('FillRect', screen.w, 0);
            Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0, 1, color_sequence{j});
            Screen('FillOval', screen.w, color_sequence{j}, pd);
            Screen('Flip', screen.w, 0);
            KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
            if YorN==27, break; end
        end
        
        
        % intensity scan @ specific color
        brightness = [32, 64, 128, 255];
        color = [0 0 1];
        for j=1:length(brightness)
            Screen('FillRect', screen.w, 0);
            Screen('FillRect', screen.w, brightness(j)*color, box);
            Screen('Flip', screen.w, 0);
            KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
            if YorN==27, break; end
        end
end

Screen('CloseAll');

end