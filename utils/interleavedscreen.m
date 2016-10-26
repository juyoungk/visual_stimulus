function ex = interleavedscreen(ex, stimidx)
% stimidx: current stimidx

    % bg screen
    Screen('FillRect', ex.disp.winptr, ex.disp.bgcol);
%     Screen('DrawText', ex.disp.winptr, ['Next stimulus : ', ex.stim{stimidx+1}.function], ...
% 		50, 50, ex.disp.white);
    Screen('Flip', ex.disp.winptr, 0);
    
    pause(2);

end