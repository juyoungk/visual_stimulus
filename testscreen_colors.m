function testscreen_colors(debug, intensity_factor)

if nargin == 0 
    debug =1;
    intensity_factor = 0.5;
elseif nargin == 1
    intensity_factor = 0.5;
end

color_sequence = { [255, 0, 0]* intensity_factor, 
                   [0, 255, 0]* intensity_factor, 
                   [0, 0, 128]* intensity_factor
                 };             
n_colors = length(color_sequence);
               
commandwindow
addpath('HelperFunctions/')

screen = InitScreen(debug);
waitframes = 1;

    boxL_um = 50; %unit: um
    bar_width = 3; % # boxes.
    boxL = Pixel_for_Micron(boxL_um);  %um to pixels
    disp(['Pixel N for ', num2str(boxL_um), 'um =  ', num2str(boxL), ' px']);
    disp(['Pixel N for ', num2str(100), 'um =  ', num2str(PIXELS_PER_100_MICRONS), ' px']);
    
    N = 31; % determines the stim size
    stimsize = boxL*N;
    % 3-2. MEA Box (150um = MEA length = 30 * 5)
    boxL_ref = 7*PIXELS_PER_100_MICRONS;
    
 % Define the obj Destination Rectangle
objRect = RectForScreen(screen,stimsize,stimsize,0,0);

 for i=1:4
    % 2. checker
    %
    %Screen('FillRect', screen.w, screen.gray);
    [x, y] = meshgrid(1:N, 1:N);
    texMatrix = mod(x+y,2)*2*screen.gray;
    % texture pointer
    objTex  = Screen('MakeTexture', screen.w, texMatrix);
    % display last texture
    for j=1:n_colors
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0, 1, color_sequence{j});
        Screen('FillOval', screen.w, screen.white, DefinePD);
         %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect]
        %[,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [,
        %modulateColor] [, textureShader] [, specialFlags] [, auxParameters]);
        Screen('Flip', screen.w, 0);
        KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
        if YorN==27, break; end;
    end
    
end

Screen('CloseAll');

end