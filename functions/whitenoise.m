function ex = whitenoise(ex, replay)
%
% ex = whitenoise(ex, replay)
%
% Required parameters:
%   length : float (length of the experiment in minutes)
%   framerate : float (rough framerate, in Hz)
%   ndims : [int, int] (dimensions of the stimulus)
%   dist: 'gaussian' or 'binary'
%
% Optional parameters:
%   seed : int (for the random number generator. Default: 0)
%
% Runs a receptive field mapping stimulus

  if replay

    % load experiment properties
    numframes = ex.numframes;
    me = ex.params;

    % set the random seed
    rs = getrng(me.seed);

  else

    % shortcut for parameters
    me = ex.stim{end}.params;
    

    % initialize the VBL timestamp
    vbl = GetSecs();

    % initialize random seed
    if isfield(me, 'seed')
      rs = getrng(me.seed);
    else
      rs = getrng();
    end
    ex.stim{end}.seed = rs.Seed;

    % compute flip times from the desired frame rate and length
    if me.framerate > ex.disp.frate
        error('Your monitor does not support a frame rate higher than %i Hz', ex.disp.frate);
    end
    flipsPerFrame = round(ex.disp.frate / me.framerate)
    ex.stim{end}.framerate = 1 / (flipsPerFrame * ex.disp.ifi);
    flipint = ex.disp.ifi * (flipsPerFrame - 0.25);
    pd_period = round(ex.stim{end}.framerate); % frames per second

    % store the number of frames
    numframes = ceil((me.length * 60) * ex.stim{end}.framerate);
    ex.stim{end}.numframes = numframes;
    
    % store timestamps
    ex.stim{end}.timestamps = zeros(ex.stim{end}.numframes,1);
    
    % Make HiDens masking texture
    %ex = get_hidens_mask(ex);

  end
  
  % write_mask
  c_mask = me.c_mask;
  Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);
  
  % loop over frames
  for fi = 1:numframes

    % generate stimulus pixels
    if strcmp(me.dist, 'gaussian')
      frame = 1 + me.contrast * randn(rs, me.ndims);
    elseif strcmp(me.dist, 'uniform')
      % this is actually uniformly distributed
      frame = 2 * rand(rs, me.ndims) * me.contrast + (1 - me.contrast);
    elseif strcmp(me.dist, 'binary')
      % true binary would be
      frame = floor(2 * rand(rs, me.ndims)) * me.contrast + (1 - me.contrast);
    else
      error(['Distribution ' me.dist ' not recognized! Must be gaussian or binary.']);
    end

    if replay

      % write the frame to the hdf5 file
      h5write(ex.filename, [ex.group '/stim'], uint8(me.gray * frame), [1, 1, fi], [me.ndims, 1]);

    else
        
      % make the texture
      texid = Screen('MakeTexture', ex.disp.winptr, uint8(ex.disp.white * frame));
    
      % draw the texture, then kill it
      Screen('DrawTexture', ex.disp.winptr, texid, [], ex.disp.dstrect, 0, 0);
      Screen('Close', texid);
      
      % Draw HiDens masking texture
      %Screen('DrawTexture', ex.disp.winptr, ex.disp.hidens_mask, [], [], 90);
      
      % update the photodiode with the top left pixel
      if fi == 1
        pd = ex.disp.pd_color;
      elseif mod(fi, pd_period) == 1
        pd = ex.disp.pd_color * 0.5;
      else  
        pd = 0;
      end
      Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 1]);
      Screen('FillOval', ex.disp.winptr, pd, ex.disp.pdrect);
      Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);

      % flip onto the scren
      %Screen('DrawingFinished', ex.disp.winptr);
      %vbl = Screen('Flip', ex.disp.winptr, vbl + flipint);
      
      % flip onto the scren
      Screen('DrawingFinished', ex.disp.winptr);
      [vbl, ~, ~, missed] = Screen('Flip', ex.disp.winptr, vbl + flipint);
      if (missed > 0)
            % A negative value means that dead- lines have been satisfied.
            % Positive values indicate a deadline-miss.
            if (fi > 1)
                fprintf('(Whitenoise) frame index %d (%.2f sec): flip missed = %f\n', fi, fi/me.framerate, missed);
                ex.disp.missed = ex.disp.missed + 1;
            end
      end


      % save the timestamp
      ex.stim{end}.timestamps(fi) = vbl;

      % check for ESC
      ex = checkkb(ex);
      if ex.key.keycode(ex.key.esc)
        fprintf('ESC pressed. Quitting.')
        break;
      end

    end

  end

end
