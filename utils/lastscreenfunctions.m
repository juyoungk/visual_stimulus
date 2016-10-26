function ex = lastscreenfunctions(ex)

    % gray screen at last
    Screen('FillRect', ex.disp.winptr, ex.disp.bgcol);
    Screen('Flip', ex.disp.winptr, 0);
    
    % pause until Keyboard pressed
    KbWait(-1,2); 
end
    
    