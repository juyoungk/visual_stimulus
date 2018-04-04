function ex = naturalmovie2(ex, replay)
%NATRUALMOVIE2: 
%   - Movie can contain color channels. [frames, ros, cols, channels]
%   - Movie files will be played in order. (0403 2018 JY)
%   - No contrast option.
%
% ex = naturalmovie(ex, replay)
%
% Required parameters:
%   length : float (length of the experiment in minutes)
%   framerate : float (rough framerate, in Hz)
%   ndims : [int, int] (dimensions of the stimulus)
%   moviedir: string (location of the movies)
%   movext: string (file extension for the movies)
%   jumpevery: int (number of frames to wait before jumping to a new image)
%   jitter: strength of jitter
%
% Optional parameters:
%   seed : int (for the random number generator. Default: 0)
%
% Runs a natural movie from specified natural_movie_frames.mat file
% 
% Movie file format: [frame, rows, cols]. already rescaled. 
  
  
          
  if replay

    % load experiment properties
    numframes = ex.numframes;
    me = ex.params;

    % set the random seed
    rs = getrng(me.seed);

  else

    % shorthand for parameters
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
    flipsPerFrame = round(ex.disp.frate / me.framerate);
    ex.stim{end}.framerate = 1 / (flipsPerFrame * ex.disp.ifi);
    flipint = ex.disp.ifi * (flipsPerFrame - 0.25);

    % darken the photodiode
    Screen('FillOval', ex.disp.winptr, 0, ex.disp.pdrect);
    vbl = Screen('Flip', ex.disp.winptr, vbl + flipint);

    % store the number of frames (set by duraion)
    numframes = ceil((me.length * 60) * ex.stim{end}.framerate);
    ex.stim{end}.numframes = numframes;
    
    % store timestamps
    ex.stim{end}.timestamps = zeros(ex.stim{end}.numframes,1);

  end


  % load natural movie frames
  files = dir(fullfile(me.moviedir, me.movext));
  nummovies = length(files);
  if nummovies < 1
      error('no movies in designated folder');
  end
  movies = cell(nummovies, 1);

  for fileidx = 1:nummovies
    movies(fileidx) = struct2cell(load(fullfile(me.moviedir, files(fileidx).name)));
  end

  % write_mask
  c_mask = me.c_mask;
  Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);
  
  % scale factor: larger patch, gradual jitter
  s_factor = me.scale;
  
  % jitter amp
  jitter_amp = me.jitter_var/s_factor; 
  
  % total frame
  totFrames = 0;
  
  % margin for subpart (1:3 for left:right)
  m = 0.2;
  
  % loop over files
  for fileidx = 1:nummovies  
    
    %mov = movies{randi(rs, nummovies)};
    mov = uint8(movies{fileidx});    
    movNumFrames = size(mov, 1);
      
    for fi = 1:movNumFrames % stimulus frame
        
          % which frame you want to start? just current stim frame
          % index.
          current_frame = fi; 
          % image
          img = squeeze(mov(current_frame,:,:,:));
          [rows, cols] = size(img);

        if mod(fi, me.jumpevery) == 1
        %% Saccade: Pick new subpart
              % possible range for initial points
              ii = max(round(size(img,1)*(1-m) - me.ndims(1)), 1);
              jj = max(round(size(img,2)*(1-m) - me.ndims(2)), 1);
              % location for the subpart
              i_row = randi(rs, ii) + round(0.25*m*size(img,1)) - 1;
              i_col = randi(rs, jj) + round(0.25*m*size(img,2)) - 1;
              % just center? 
%               i_row = 200;
%               i_col = 400;
        else 
        %% Jitter      
              % jitter from the previous x, y locations.
              i_row = max(min(size(img,1) - me.ndims(1), i_row + round(jitter_amp * randn(rs, 1))), 1);
              i_col = max(min(size(img,2) - me.ndims(2), i_col + round(jitter_amp * randn(rs, 1))), 1);
        end
        % check the end points.
        i_row_end = min(i_row + me.ndims(1) - 1, rows);
        i_col_end = min(i_col + me.ndims(2) - 1, cols);
        
        % subpart of the image
            %frame = img(xstart:(xstart + me.ndims(1) - 1), ystart:(ystart + me.ndims(2) - 1)) * me.contrast + (1 - me.contrast) * ex.disp.gray;
        % no contrast option.
        frame = img(i_row:i_row_end, i_col:i_col_end,   :);
            
        % downsampling (more natural fixational eye movement with same variance)
        frame = imresize(frame, s_factor, 'bilinear');
        % uint8 output? 
        %assignin('base','frameFromMovie',frame)

        if replay
          % write the frame to the hdf5 file
          h5write(ex.filename, [ex.group '/stim'], frame, [1, 1, fi], [me.ndims, 1]);
        else
          % make the texture
          texid = Screen('MakeTexture', ex.disp.winptr, frame);
          %texid = Screen('MakeTexture', ex.disp.winptr, frame, optimizeForDrawAngle=0, specialFlags=4);
          
%                   If 'specialFlags' is set to 4 then PTB tries to use an especially fast method of
%         texture creation. This method can be at least an order of magnitude faster on
%         some systems. However, it only works on modern GPUs, only for certain maximum
%         image sizes, and with some restrictions, e.g., scrolling of textures or
%         high-precision filtering may not work at all or as well. Your mileage may vary,
%         so only use this flag if you need extra speed and after verifying your stimuli
%         still look correct. The biggest speedup is expected for creation of standard 8
%         bit integer textures from uint8 input matrices, e.g., images from imread(), but
%         also for 8 bit integer Luminance+Alpha and RGB textures from double format input
%         matrices.

          % draw the texture, then kill it
          % winptr: win pointer. dstrect can define the actual size.
          Screen('DrawTexture', ex.disp.winptr, texid, [], ex.disp.dstrect, 0, 0); 
          Screen('Close', texid);

          % update the photodiode with the top left pixel on the first frame
          if fi == 1
            pd = ex.disp.white;
          elseif mod(fi, me.jumpevery) == 1
            pd = ex.disp.white * 0.5;
          else
            pd = 0;
          end
          Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 1]);
          Screen('FillOval', ex.disp.winptr, pd, ex.disp.pdrect);
          Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);

          % flip onto the screen
          Screen('DrawingFinished', ex.disp.winptr);
          [vbl, ~, ~, missed] = Screen('Flip', ex.disp.winptr, vbl + flipint);
          if (missed > 0)
                % A negative value means that dead- lines have been satisfied.
                % Positive values indicate a deadline-miss.
                if (fi > 1)
                    fprintf('(NaturalMovie) frame index %d (%.2f sec): flip missed = %f\n', fi, fi/me.framerate, missed);
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
    totFrames = totFrames + movNumFrames
  end
end

function xn = rescale(x)
  xmin = min(x(:));
  xmax = max(x(:));
  xn = (x - xmin) / (xmax - xmin);
end
