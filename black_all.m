function black_all
 
commandwindow
addpath('HelperFunctions/')

bg_color = [0 0 0];

i_screen = Screen('Screens');

Screen('Preference', 'SkipSyncTests',1);

for i_screen = 0 % screen 0 is the total screen.

    [w, ~] = PsychImaging('OpenWindow', i_screen, bg_color);
    Screen('FillRect', w, [0 0 0]);
    Screen('Flip', w, 0);
    
end
    
KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);

Screen('CloseAll');

end