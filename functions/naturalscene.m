function ex = naturalscene(ex, replay)
%
% ex = naturalscene(ex, replay)
%
% Required parameters:
%   length : float (length of the experiment in minutes)
%   framerate : float (rough framerate, in Hz)
%   ndims : [int, int] (dimensions of the stimulus)
%   imgdir: string (location of the images)
%   imgext: string (file extension for the images)
%   jumpevery: int (number of frames to wait before jumping to a new image)
%   jitter: strength of jitter
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

    % shorthand for parameters % end? current id!
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
    flipsPerFrame = round(ex.disp.frate / me.framerate); % ~ waitframes
    ex.stim{end}.framerate = 1 / (flipsPerFrame * ex.disp.ifi);
    flipint = ex.disp.ifi * (flipsPerFrame - 0.25);

    % darken the photodiode
    Screen('FillOval', ex.disp.winptr, 0, ex.disp.pdrect);
    vbl = Screen('Flip', ex.disp.winptr, vbl + flipint);

    % store the number of frames
    numframes = ceil((me.length * 60) * ex.stim{end}.framerate);
    ex.stim{end}.numframes = numframes;
    
    % store timestamps
    ex.stim{end}.timestamps = zeros(ex.stim{end}.numframes,1);

    % ex = get_hidens_mask(ex);

  end


  % load natural images
  files = dir(fullfile(me.imgdir, me.imgext));
  numimages = length(files);
  if numimages < 1
      error('no images in designated folder');
  end
  images = cell(numimages, 1);
  for fileidx = 1:numimages
    images(fileidx) = struct2cell(load(fullfile(me.imgdir, files(fileidx).name)));
  end
  
  % write_mask
  c_mask = me.c_mask
  %c_mask = [0 1 0];
  Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);
  
  % loop over frames
  for fi = 1:numframes

    % pick a new image and a new start point (x0, y0)
    if mod(fi, me.jumpevery) == 1
      i = randi(rs, numimages);
      img = rescale(images{i});
      xstart = randi(rs, size(img,1) - 2*me.ndims(1)) + me.ndims(1);
      ystart = randi(rs, size(img,2) - 2*me.ndims(2)) + me.ndims(2);
    % jitter
    else
      xstart = max(min(size(img,1) - me.ndims(1), xstart + round(me.jitter * randn(rs, 1))), 1); % me.jitter = variance
      ystart = max(min(size(img,2) - me.ndims(2), ystart + round(me.jitter * randn(rs, 1))), 1);
    end
    % get the new image patch (or frame)
    frame = 2 * img(xstart:(xstart + me.ndims(1) - 1), ystart:(ystart + me.ndims(2) - 1)) * me.contrast + (1 - me.contrast);
    % downsampling (more natural fixational eye movement with same
    % variance)
    % by imsize?
    
    %
    if replay
      % write the frame to the hdf5 file
      h5write(ex.filename, [ex.group '/stim'], uint8(me.gray * frame), [1, 1, fi], [me.ndims, 1]);
    else

      % make the texture
      texid = Screen('MakeTexture', ex.disp.winptr, ex.disp.gray * frame);

      % draw the texture, then kill it
      % srcRect is not defined. Use the whole frame (or patch). []
      Screen('DrawTexture', ex.disp.winptr, texid, [], ex.disp.dstrect, 0, 0);
      Screen('Close', texid);

      %Screen('DrawTexture', ex.disp.winptr, ex.disp.hidens_mask, [], [], 90);
      %Screen('FillRect', ex.disp.winptr, 127);

      % update the photodiode with the top left pixel
      if fi == 1
        pd = ex.disp.pd_color;
      elseif mod(fi, me.jumpevery) == 1
        pd = ex.disp.pd_color * 0.5;
      else
        pd = 0;
      end
      Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 1]);
      Screen('FillOval', ex.disp.winptr, pd, ex.disp.pdrect);
      Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);

      % flip onto the scren
      Screen('DrawingFinished', ex.disp.winptr);
      [vbl, ~, ~, missed] = Screen('Flip', ex.disp.winptr, vbl + flipint);
      if (missed > 0)
            % A negative value means that dead- lines have been satisfied.
            % Positive values indicate a deadline-miss.
            if (fi > 1)
                fprintf('(Naturalscene) frame index %d (%.2f sec): flip missed = %f\n', fi, fi/me.framerate, missed);
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

function xn = rescale(x)
  xmin = min(x(:));
  xmax = max(x(:));
  xn = (x - xmin) / (xmax - xmin);
end
