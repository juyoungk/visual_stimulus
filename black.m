function black
 
commandwindow
addpath('HelperFunctions/')

screen = InitScreen(0);

Screen('Screens');

Screen('FillRect', screen.w, [0 0 0]);
Screen('Flip', screen.w, 0);
KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);

Screen('CloseAll');

end