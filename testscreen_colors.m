function testscreen_colors(debug, intensity_factor)

if nargin == 0 
    debug =1;
    intensity_factor = 1;
elseif nargin == 1
    intensity_factor = 1;
end

color_sequence = { [255, 0, 0]* intensity_factor, 
                   [0, 255, 0]* intensity_factor, 
                   [0, 0, 255]* intensity_factor
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

 for i=1:2
    % 3-0. Stim area (0 intensity outside of the stim area)
    box =  RectForScreen(screen,stimsize,stimsize,0, 0);
        % color change @ white intensity
        for j=1:n_colors
            % bright stim area on dark
            Screen('FillRect', screen.w, 0);
            Screen('FillRect', screen.w, color_sequence{j}, box);
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