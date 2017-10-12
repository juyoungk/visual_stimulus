function white_screen
 
commandwindow
addpath('HelperFunctions/')

Screen('Preference', 'SkipSyncTests',1);
screen = InitScreen(0);

Screen('FillRect', screen.w, [0 0 0]);

radius = 128 % px
centerX = 0;
centerY = 0;
rect = RectForScreen(screen, 2*radius, 2*radius, centerX, centerY);

color = [0 1 1]*screen.white;

Screen('FillOval', screen.w, color, rect);
Screen('Flip', screen.w, 0);
KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);

Screen('CloseAll');

end