function ex = grayscreen(ex, replay)
% Present gray screen on dstrect

  if replay
    
    return
    
  else
    % shortcut for parameters
    me = ex.stim{end}.params;
    % initialize the VBL timestamp
    vbl = GetSecs();
  end
  
  % default framerate
  framerate = 20;
  stim_ifi = 1/framerate;
  
  % Normalized flips
  flipsPerFrame = round(stim_ifi/ex.disp.ifi);
  stim_ifi = flipsPerFrame * ex.disp.ifi; % integer times of nominal ifi.
  
  % Optimized framrate
  framerate = 1/stim_ifi; 
  
  % 
  flipint = ex.disp.ifi * (flipsPerFrame - 0.125);
  
  %
  numframes = me.length * framerate;
  
  % weight factor for mean 
%   if isfield(me, 'w_mean')
%       weight_mean = me.w_mean;
%   else
%       weight_mean = 1;
%   end

  if isfield(me, 'c_mask')
      c_mask = me.c_mask;
  else
      c_mask = [1 1 1];
  end


  % Presenting screen in the loop in order to check ESC
  for fi = 1:numframes
      
      % gray screen
      Screen('FillRect', ex.disp.winptr, ex.disp.graycolor, ex.disp.dstrect);
      
      % pd
      if fi == 1
          pd = ex.disp.pd_color;
          pdrect = ex.disp.pdrect;
          Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 1]);
          Screen('FillOval', ex.disp.winptr, pd, pdrect);
          Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);
      end
      
      
      [vbl, ~, ~, ~] = Screen('Flip', ex.disp.winptr, vbl + flipint);
      
      % check for ESC
      ex = checkkb(ex);
      if ex.key.keycode(ex.key.esc)
          fprintf('ESC pressed. Quitting.')
          break;
      end
      
  end

  
end
