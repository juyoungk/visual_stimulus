function screen = testscreen_colors(debug, intensity_factor)
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
% don't care the sync test for color test
Screen('Preference', 'SkipSyncTests',1);

screen = InitScreen(debug);
disp(['screen.white = ',num2str(screen.white)]);
disp(['screen.black = ',num2str(screen.black)]);

    boxL_um = 60; %unit: um
    boxL = Pixel_for_Micron(boxL_um);  %um to pixels
    
    N = 15; % determines the stim size
    pd_shift_from_center = 2.5; % mm
    stimsize = Pixel_for_Micron(boxL_um*N);
    
    disp(['Pixel N for ', num2str(boxL_um), ' um =  ', num2str(boxL), ' px']);
    disp(['Pixel N for ', num2str(100), ' um =  ', num2str(PIXELS_PER_100_MICRONS), ' px']);
    disp(['Pixel N for ', num2str(boxL_um*N), ' um =  ', num2str(stimsize), ' px']);
    
% Define the obj Destination Rectangle
objRect = RectForScreen(screen,stimsize,stimsize,0,0);
box     = RectForScreen(screen,stimsize,stimsize,0,0);
% pd rect
pd = DefinePD_shift(screen.w, 'shift', pd_shift_from_center*1000);
pd_color = [screen.white, 0, 0];
randomStream = RandStream('mcg16807', 'Seed', 0);
vbl =0;
ifi = screen.ifi;

 for i=1:1
    % 1. Stim area (0 intensity outside of the stim area)
    
    % color change @ white intensity
        for j=1:n_colors
            % bright stim area on dark
            Screen('FillRect', screen.w, 0);
            Screen('FillRect', screen.w, color_sequence{j}, box);
            Screen('FillOval', screen.w, color_sequence{j}, pd);
            vbl = Screen('Flip', screen.w, vbl+ifi*0.5);
            KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
            if YorN==27, break; end
        end
        
    % 2. texture (Is there a chromatic abberation ?)
    [x, y] = meshgrid(1:N, 1:N);
    texMatrix = max(min(mod(x+y,2)*2*screen.gray, 255), 0);
    objTex  = Screen('MakeTexture', screen.w, texMatrix);
    angle = 0;
    % color change @ white intensity
        for j=1:n_colors
            % bright stim area on dark
            Screen('FillRect', screen.w, 0);
            Screen('DrawTexture', screen.w, objTex, [], objRect, angle, 0, 1, color_sequence{j});
            Screen('FillOval', screen.w, pd_color, pd);
            vbl = Screen('Flip', screen.w, vbl+ifi*0.5);
            KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
            if YorN==27, break; end
        end
        
%     % 2-2. White noise texture
%     for j=1:3
%             texWhiteNoise = (rand(randomStream, N, N)>.5)*screen.white;
%             imgMat = zeros(N, N, 3);
%             imgMat(:,:,3) = texWhiteNoise;
%             objTex  = Screen('MakeTexture', screen.w, texMatrix);
%             Screen('FillRect', screen.w, 0);
%             Screen('DrawTexture', screen.w, objTex, [], objRect, angle, 0, 1, color_sequence{j});
%             Screen('FillOval', screen.w, pd_color, pd);
%             Screen('Flip', screen.w, 0);
%             KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
%             if YorN==27, break; end
%     end
%         
        
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

% Text for getting focusing?
text = 'screen test...';
w = screen.w;
Screen('TextSize', screen.w, 48);
        for j=1:n_colors            
            % bright stim area on dark
            Screen('FillRect', screen.w, 0);
            Screen('DrawText', w, text, 0.5*screen.sizeX, 0.4*screen.sizeY, color_sequence{j});
            Screen('DrawText', w, text, 0.5*screen.sizeX, 0.5*screen.sizeY, color_sequence{j}/2);
            Screen('DrawText', w, text, 0.5*screen.sizeX, 0.6*screen.sizeY, color_sequence{j}/4);
            Screen('FillOval', screen.w, pd_color, pd);
            Screen('Flip', screen.w, 0);
            KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
            if YorN==27, break; end
        end
 
Screen('CloseAll');

end