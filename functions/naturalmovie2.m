function ex = naturalmovie2(ex, replay, movies)
%NATRUALMOVIE2: 
%   - Movie can contain color channels. [frames, ros, cols, channels]
%   - Movie files will be played in order. (0403 2018 JY)
%   - No contrast option.
%   - Repeat option.
%   - startframe (same for all movies)
%
% ex = naturalmovie2(ex, replay, movies)
%
%   - movies : cell array
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
  
  % movie input from WorkSpace
  if nargin < 3
      movies = [];
  end
  
  % 
  if replay

        % load experiment properties
        numframes = ex.numframes;
        me = ex.params;

        % set the random seed
        rs = getrng(me.seed);
        
        % how to replay same movie with movies input?
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
        flipint = ex.disp.ifi * (flipsPerFrame - 0.15);

        % darken the photodiode
        Screen('FillOval', ex.disp.winptr, 0, ex.disp.pdrect);
        vbl = Screen('Flip', ex.disp.winptr, vbl + flipint);
  end

  % Movie input
  if ~isempty(movies)
      % movie from input WS variables      
      nummovies = numel(movies);
  else
      % movie from files
      files = dir(fullfile(me.moviedir, me.movext));
      nummovies = length(files);
      if nummovies < 1
          error('no movies in designated folder');
      end
      movies = cell(nummovies, 1);

      % laod movie files
      for fileidx = 1:nummovies
        movies(fileidx) = struct2cell(load(fullfile(me.moviedir, files(fileidx).name)));
      end
  end
  
  % Numframes & Timestamps (replay doesn't need this information)
  if ~replay
      totframes = 0;
      for i = 1:nummovies
        [nframes, ~, ~, ~] = size(movies{i});
        totframes = totframes + nframes;
      end
      % frames by duration (if it exists)
      if isfield(me, 'length')
        nframes_length = floor((me.length * 60) * ex.stim{end}.framerate);
      else
        nframes_length = NaN;
      end
      % Final numframes
      numframes = min(nframes_length, totframes);
      fprintf('%d/%d frames will be presented. (%.1f sec long movie)\n', numframes, totframes, me.length*60);
      ex.stim{end}.numframes = numframes;
      % store timestamps
      ex.stim{end}.timestamps = zeros(numframes,1);
  end

  % write_mask
  c_mask = me.c_mask;
  if ~replay
    Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);
  end
  
  % scale factor: larger patch, gradual jitter
  s_factor = me.scale;
  ndims_scaled = me.ndims;
  ndims_scaled(1) = me.ndims(1) * s_factor;
  ndims_scaled(2) = me.ndims(2) * s_factor;
  Ndims = size(me.ndims, 2);
  
  % jitter amp
  jitter_amp = me.jitter_var/s_factor; 
  
  % margin for subpart (1:3 for left:right)
  m = 0.2;
  
  % mov (or file) ID
  if isfield(me, 'mov_id')
      mov_ids = me.mov_id;
  else
      mov_ids = 1:nummovies;
  end
  if mov_ids == 0 % 0 means all movies
      mov_ids = 1:nummovies;
  end    
  
  % repeat number
  if isfield(me, 'repeat')
      n_repeats = me.repeat;
  else
      n_repeats = 1;
  end
  disp(['Natural movies will be repeated by ', num2str(n_repeats), ' times.']);
  
  % start frame
  if isfield(me, 'startframe')
      startframe = me.startframe;
  else
      startframe = 1;
  end
   
  for rr = 1:n_repeats
      % initialization
      ti = 0; % frame index as total. increased when the frame starts. 
      FLAG_stop = false;
      fprintf('%d/%d presentation of natural movies (%.1f secs long).\n', rr, n_repeats, me.length * 60);
      rs = getrng(rs.Seed);
      
      if rr>1 && replay % no repeat for replay
          break;
      end
      
      for fileidx = mov_ids % loop over movie files

        if FLAG_stop % if frames number reaches to the specified movie duration
            break;
        end
        %mov = movies{randi(rs, nummovies)};
        mov = movies{fileidx};    
        movNumFrames = size(mov, 1);

        % # of pixels in display for 1 pixel in stimulus frame.
        % isotropic pixel size (integer) along x and y
        L = ex.disp.aperturesize;
        px = min( ceil(L/ndims_scaled(2)), ceil(L/ndims_scaled(1)) );  
        % Define dst rect as integer multiples of the frame size.
        Lx = px * ndims_scaled(2);
        Ly = px * ndims_scaled(1);
        ex.disp.aperturesize_movies_mm = [Lx Ly]*ex.disp.umperpix/1000.;

        dstrect = CenterRectOnPoint(...	
                        [0 0 Lx Ly], ...
                        ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y); 
            
        for fi = startframe:movNumFrames % stimulus frame id in current movie
              % frame id as total 
              ti = ti + 1;
              % frame id in movie (you might want to pick random frame)
              current_frame = fi; 
              % image
              img = squeeze(mov(current_frame,:,:,:));
              [rows, cols] = size(img);

            if mod(fi - startframe, me.jumpevery) == 0
            %% Saccade: Pick new subpart. It should happen first.
                  % possible range for initial points
                  ii = max(round(size(img,1)*(1-m) - me.ndims(1)), 1);
                  jj = max(round(size(img,2)*(1-m) - me.ndims(2)), 1);
                  % location for the subpart
                  i_row = randi(rs, ii) + round(0.25*m*size(img,1)) - 1;
                  i_col = randi(rs, jj) + round(0.25*m*size(img,2)) - 1;

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
            %  .* ex.disp.whitecolor ? white direction....
            frame = img(i_row:i_row_end, i_col:i_col_end,   :);

            % downsampling (more natural fixational eye movement with same variance)
            frame = uint8(imresize(frame, s_factor, 'bilinear'));
            % uint8 output? 
            %assignin('base','frameFromMovie',frame)

            if replay
              % write the frame to the hdf5 file
              % mask effect
              frame = uint8(color_weight(frame, c_mask));
              %h5write(ex.filename, [ex.group '/stim'], frame, [1, 1, 1, ti], [me.ndims*s_factor, 3, 1]);
              h5write(ex.filename, [ex.group '/stim'], frame, [ones(1, Ndims), ti], [ndims_scaled, 1]);
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
              Screen('DrawTexture', ex.disp.winptr, texid, [], dstrect, 0, 0); 
              Screen('Close', texid);

              % update the photodiode with the top left pixel on the first frame
              if fi == startframe
                pd = ex.disp.white;
              %elseif mod(fi, me.jumpevery) == 1
              elseif mod(fi - startframe, me.jumpevery) == 0
                pd = ex.disp.white * 0.4;
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
                    if (ti > 1)
                        fprintf('(NaturalMovie2) frame index %d (%.2f sec): flip missed = %f\n', ti, ti/me.framerate, missed);
                        ex.disp.missed = ex.disp.missed + 1;
                    end
              end

              % save the timestamp
              ex.stim{end}.timestamps(ti) = vbl;

              % check for ESC
              ex = checkkb(ex);
              if ex.key.keycode(ex.key.esc)
                fprintf('ESC pressed. Quitting.')
                FLAG_stop = true;
                break;
              end

            end % Flip or Replay

            if ti == numframes
                 FLAG_stop = true;
                 break;
            end
        end
        
      end % loop over mov files
  end % loop over repeats
  
  if ~replay
      %ex.stim{end}.numframes = totFrames;
      ex.stim{end}.numframes_played = ti; % played frame numbers
  end
end

function xn = rescale(x)
  xmin = min(x(:));
  xmax = max(x(:));
  xn = (x - xmin) / (xmax - xmin);
end

function C = color_matrix(A, color)
% color as a weight vector, form a 3D color matrix from 2D matrix A.
n = numel(color);

C = zeros([size(A), n]);

for c = 1:n
    C(:,:,c) = color(c) * A(:,:);
end

end


function C = color_weight(A, color)
% color as a weight vector.
    if ndims(A) ~= 3
        error('Input A should have dim 3 color matrix');
    end
    n = numel(color);
    n_channel = size(A, 3);
    if n ~= n_channel
        error('# of color channels should be same for A and color vector');
    end
    C = zeros(size(A));

    for c = 1:n
        C(:,:,c) = color(c) * A(:,:,c);
    end

end
