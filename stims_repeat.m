function ex = stims_repeat(stim, n_repeats, varargin)
%STIMS_REPEAT present the given stimulus (struct) by n_repeats times using
%PTB. Stimulus can be [n m] grating or annulus. Flash is a [1 1] case of
%grating and turn on/off by shifting [2 1] grating. 
%
%Phase shift is always along the x axis.
%
%   noise: uniformly-distributed whitenoise only. ndims = 3 only.
%
%   shift_per_frame: always x direction.
%   shift_max: 
%
% gap between center and bg: 0.2mm
% 
    gray_margin = 0.25;
    p = ParseInput(varargin{:});
    if nargin < 2
        n_repeats = 3;
    end
    debug_exp = p.Results.debug;
    ex_mode = p.Results.mode;
    ex_title = p.Results.title;
    % default conditions
    
    framerate = p.Results.framerate;
    
    addpath('HelperFunctions/')
    addpath('utils/')
    commandwindow
    try
          % today's directory. Create if it doesn't exist for ex history log.
          basedir = fullfile('logs', datestr(now, 'yy-mm-dd'));
          if exist(basedir,'dir') == 0
              mkdir(basedir);
          end

          % id for FOV or Exp.
          loc_id = input(['\nNEW EXPERIMENT: ', ex_title, '\nFOV or Loc name? (e.g. 1 or 2 ..) ']);
          if isempty(loc_id)
              loc_id = 99;
          end
          ex_name = ['loc',num2str(loc_id), '_', ex_title];
            
          % Construct an experimental structure array
          ex = initexptstruct(debug_exp);
          % Initialize the keyboard
          ex = initkb(ex);
          
          % Initalize the visual display w/ offset position
          ex = initdisp(ex, 1500, -100);
              stim_ifi = 1/framerate;                               % framerate and ifi I ask 
              stim_ifi = round(stim_ifi/ex.disp.ifi) * ex.disp.ifi; % integer times of nominal ifi.
              [stim(:).framerate] = deal(framerate);
              ex.framerate = framerate;
              ex.stim_ifi_normalized = stim_ifi;
              ex.name = ex_name;
              fprintf('\nexp: %s (stim ifi = %.3f)\n\n', ex_name, stim_ifi);
              
          % wait for trigger
          ex = waitForTrigger(ex);
          
          % save stim info
          numStim = numel(stim);
%           ex.stim = cell(1,numStim);
%           for e=1:numStim
%             ex.stim{e} = stim(e);
%           end
          ex.stim = stim;
          ex.n_repeats = n_repeats;
          ex.name = ex_name;
          t1 = clock;
            
          % initialize the VBL timestamp
          vbl = GetSecs();
          
            for i = 1:n_repeats
                
                % PD trigger will happen at the start of the k-th stimulus 
                repeat_trigger_k = 1;
                
                for k = 1:numStim % current stim
                    
                    s = stim(k);
                    if isempty(s.ndims)
                        continue;
                    end
                    
                    % color & delay
                    if ~isfield(s, 'color') || isempty(s.color)
                        s.color = [1 1 1];
                    end
                    if ~isfield(s, 'delay') || isempty(s.delay)
                        s.delay = 0;
                    end
                    if ~isfield(s, 'cycle') || isempty(s.cycle)
                        s.cycle = 1;
                    end
                    % FLAG for center drawing
                    if ~isfield(s, 'draw_center') || isempty(s.draw_center)
                        s.draw_center = true;
                    end
                    if ~isfield(s, 'tag') || isempty(s.tag)
                        s.tag = '';
                    end
                    if ~isfield(s, 'shift_max') || isempty(s.shift_max)
                        s.shift_max = 0;
                    end
                    
                    % Print where I am
                    fprintf('(stim repeats %d/%d) %8s stimulus (%2d/%d)\n', i, n_repeats, s.tag, k, numStim);
                    
                    % start screen: 1. push the (big) stim trigger to next k 2. plays only once.
                    if contains(s.tag, 'start screen')
                        repeat_trigger_k = repeat_trigger_k + 1;
                        if i > 1 % only play once, not repeating.
                            continue; % Go to next stimulus
                        end
                    end
                    
                    % frame numbers
                    frames_per_period = round(framerate * s.half_period * 2);
                    frameid_ON = round(frames_per_period/2.) + 1; % frame id for shift (or ON or id for phase =1).
                    
                    % Annulus stim
                    if isfield(s, 'Annulus') && ~isempty(s.Annulus)
                        L_ann = s.Annulus   * 1000 * ex.disp.pix_per_um;
                        w_ann = s.w_Annulus * 1000 * ex.disp.pix_per_um;
                    else
                        L_ann = 0;
                        w_ann = 0;
                    end
                    L_ann_frames = linspace(L_ann(1), L_ann(end), frames_per_period);
                    
                    % dims
                    L = s.sizeCenter * 1000 * ex.disp.pix_per_um; % px
                    L_gray = (s.sizeCenter + gray_margin)*1000*ex.disp.pix_per_um;
                    
                    % [row col] convention
                    nx = s.ndims(2);
                    ny = s.ndims(1);
                    
                    % dim+1 checkers
                    checkers_center = gen_checkers(nx + 1, ny + 1 + s.shift_max); % 0 and 1 checkers
                    checkers_center = color_matrix(checkers_center, s.color .* ex.disp.whitecolor);
                    
                    % make the texture
                    ct_texid = Screen('MakeTexture', ex.disp.winptr, uint8(checkers_center));
                    
                    % texture dst rect (integer times checkers)
                    w_pixels_x = round(L/nx);
                    w_pixels_y = round(L/ny);
                    % if isfield(s, 'w_pixel') || ~isempty(s.w_pixel)
                    % end
                    w_pixels = min(w_pixels_x, w_pixels_y);
%                     % Num of checkers (px-norm.) within center
%                     n_checkers = floor( L/w_pixels_x );                    
                    Lx = w_pixels_x * nx;
                    Ly = w_pixels_y * ny;
                    Lchecker = max(Lx, Ly);
                    %
                    ex.stim(k).L_optimized_px = Lchecker;
                    % dst for grating stim
                    if any(s.ndims(1:2) > [1, 1]) % compare first 2 dims. 3 dim is color channel.
                        fprintf('[%d, %d] display px per checker ~ [%.0f, %.0f] um. Presentation size L = %.1f um\n',...
                            w_pixels_x, w_pixels_y, w_pixels_x*ex.disp.um_per_px, w_pixels_y*ex.disp.um_per_px, Lchecker*ex.disp.um_per_px);
                    end
                    ct_checker_rect = CenterRectOnPoint(...	
                              [0 0 Lchecker Lchecker], ...
                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y); 
                    % dst rect for center: Mask
                    ct_dst_rect = CenterRectOnPoint(...	
                              [0 0 L L], ...
                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y);
                    % gray dst rect : rect for margin btw ct and bg
                    gray_rect = CenterRectOnPoint(...	
                              [0 0 L_gray L_gray], ...
                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y);
                          
                    % BG checkers
                    if nx == 1
                        nx_bg = 1;
                    else
                        % number of lines
                        nx_bg = ceil(ex.disp.aperturesize/w_pixels_x);      
                        nx_bg = nx_bg + mod(nx_bg-nx, 2);
                    end
                    if ny == 1
                        ny_bg =1;
                    else
                        ny_bg = ceil(ex.disp.aperturesize/w_pixels_y);
                        ny_bg = ny_bg + mod(ny_bg-ny, 2);
                    end
                    Lx_bg = w_pixels_x * nx_bg;
                    Ly_bg = w_pixels_y * ny_bg;
                    L_bg = max(Lx_bg, Ly_bg);
                    bg_dst_rect = CenterRectOnPoint(...	
                              [0 0 L_bg L_bg], ...
                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y); 
                    checkers_bg = gen_checkers(nx_bg+1, ny_bg+1);
                    checkers_bg = color_matrix(checkers_bg, s.color .* ex.disp.whitecolor);     
                    bg_texid = Screen('MakeTexture', ex.disp.winptr, uint8(checkers_bg));
                    
                    % prepare whitenoise frames
                    if isfield(s, 'noise_contrast') && ~isempty(s.noise_contrast)
                        if isfield(s, 'seed')
                          rs = getrng(s.seed);
                        else
                          rs = getrng();
                        end
                        frames = randi(rs, 2, [s.ndims, frames_per_period]) - 1; % 0 or 1
                        frames = s.noise_contrast * frames + (1-s.noise_contrast)/2.;
                    end
   
                    % shift (or phase) trajectories
                        
                    % impulse or 50% duty cycle
                    if all(s.ndims(1:2) == [1 1]) && contains(s.tag, 'pulse')
                        % [1 1] flash: impulse shift 
                        shift_profile = 0.5 * ones(1, frames_per_period);
                        numPulseFrames = 5;
                        shift_profile(1:numPulseFrames) = 0;                       % 2 frames = 1/15 sec for 30Hz presentation.
                        shift_profile(frameid_ON:frameid_ON+numPulseFrames-1) = 1;
                    else
                        % default: shift profile (duty rate 50%): [0 0 .. 1 1 .. ]
                        shift_profile = 1:frames_per_period > (round(frames_per_period/2.));
                    end
                    shift_profile = double(shift_profile);

                    % shfit w/ finite speed
                    if isfield(s, 'shift_per_frame') && ~isempty(s.shift_per_frame)
                        px_per_frame = s.shift_per_frame;
                        % in phase?
                        ph_per_frame = px_per_frame/w_pixels;
                        
                        % phase (= shift) trajectories
                        shift_max = s.shift_max;
                        if shift_max == 0
                            shift_max = 2; % moving over one period.
                        end
                        shift_profile = shift_max * shift_profile;
                        ph1 = shift_max:(-ph_per_frame):0; ph1 = ph1(2:end);
                        ph2 = 0:ph_per_frame:shift_max;    ph2 = ph2(2:end);
                        if length(ph1) > frames_per_period % should be compared to half frame numbers...
                            ph1 = ph1(1:frames_per_period);
                            ph2 = ph2(1:frames_per_period);
                        end
                        numshift = length(ph1);
                        fprintf('Shift will be done over %d frames (%4.0f ms). Speed = %.2f mm/s \n',...
                            numshift, numshift*stim_ifi*1000, px_per_frame*ex.disp.um_per_px*framerate/1000. );
                        if numshift > frames_per_period/2.
                            numshift = frames_per_period/2.;
                            fprintf('Full shift over %d phase would take longer than a half repeat period. Numshift was lowered.', shift_max);
                        end 
                        %
                        shift_profile(1:numshift) = ph1(1:numshift); 
                        shift_profile(frameid_ON:frameid_ON+numshift-1) = ph2(end-numshift+1:end);
                    end

                    % phase of the annulus: flashing vs moving
                    if length(L_ann) == 2 % [a, b]: moving anuulus
                        ann_phase = ones(1, frames_per_period);
                    else % single annulus: flashing
                        ann_phase = shift_profile; % same as center object
                        ann_phase = circshift(ann_phase, round(s.delay*frames_per_period)); % flashing annulus
                    end
                    
                    % The main stimulus
                    for kk =1:s.cycle
                        
                        % assign shift trajectory to cennter pattern.
                        shift_ct = shift_profile;
                        
                        % phase for 1st cycle: can be constant
                        if isfield(s, 'phase_1st_cycle') && ~isempty(s.phase_1st_cycle)
                            if kk == 1
                                shift_ct = s.phase_1st_cycle * ones(1, frames_per_period);
                            end
                        end
                        
                        % phase for bg = phase for ccenter + delay (if defined.)
                        shift_bg = circshift(shift_ct, round(s.delay*frames_per_period));
                        
                        % presentation    
                        for fi = 1:frames_per_period
                              
                              % bg color for entire presentation field.
                              Screen('FillRect', ex.disp.winptr, ex.disp.bgcol, ex.disp.dstrect);
                            
                              if nx > 1
                                  src_rect_bg = [shift_bg(fi) 0 nx_bg + shift_bg(fi)  ny_bg];
                                  src_rect_ct = [shift_ct(fi) 0    nx + shift_ct(fi)  ny   ];
                              else
                                  src_rect_bg = [0 shift_bg(fi) nx_bg  ny_bg + shift_bg(fi)];
                                  src_rect_ct = [0 shift_ct(fi) nx     ny    + shift_ct(fi)];
                              end
                              
                              % draw the BG texture
                              if isfield(s, 'BG') && ~isempty(s.BG) && s.BG
                                  Screen('DrawTexture', ex.disp.winptr, bg_texid, src_rect_bg, bg_dst_rect, 0, 0);    
                              end
                              % gray margin rect. Center will be drawn
                              % through alpha blending. 
                              Screen('FillOval', ex.disp.winptr, ex.disp.bgcol, gray_rect); 
                              %[vbl_temp, ~, ~] = Screen('Flip', ex.disp.winptr, 0); 
                              
                              % Annulus
                              if sum(L_ann) > 0 % L_ann is either a value or a range [a, b].
                                    % dst rect for annulus
                                    L_ann_in  = round(L_ann_frames(fi) - w_ann/2.);
                                    L_ann_out = round(L_ann_frames(fi) + w_ann/2.);
                                    rect_ann_in = CenterRectOnPoint(...	
                                              [0 0 L_ann_in L_ann_in], ...
                                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y);
                                    rect_ann_out = CenterRectOnPoint(...	
                                              [0 0 L_ann_out L_ann_out], ...
                                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y);
                                  % phase [0 1] into pixel value
                                  Screen('FillOval', ex.disp.winptr, (s.color .* ex.disp.whitecolor) * ann_phase(fi), rect_ann_out);
                                  Screen('FillOval', ex.disp.winptr, ex.disp.bgcol, rect_ann_in);
                              end
                              
                              % Alpha Mask for center circle
                                % Disable alpha-blending, restrict following drawing to alpha channel:
                                Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [0 0 0 1]);
                                % Clear 'dstRect' region of framebuffers alpha channel to zero: 
                                Screen('FillRect', ex.disp.winptr, [0 0 0 0], ex.disp.dstrect); % Alpha 0 means completely clear. 
                                %Screen('FillOval', ex.disp.winptr, [0 0 0 ex.disp.white], ct_dst_rect);  
                                Screen('FillOval', ex.disp.winptr, [0 0 0 ex.disp.white], ct_dst_rect);  
                                %
                                Screen('Blendfunction', ex.disp.winptr, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                                
                              % Draw center pattern
                              %if all(s.ndims == [1,1]) && (shift_ct(fi) == 0.5)
                              if s.draw_center
                                  if shift_ct(fi) == 0.5 % 0.5 phase shift means gray or bg color.
                                    Screen('FillRect', ex.disp.winptr, ex.disp.bgcol, ct_checker_rect);  
                                  else
                                    Screen('DrawTexture', ex.disp.winptr, ct_texid, src_rect_ct, ct_checker_rect, 0, 0);
                                  end
                              end
                              
                              % Draw noise if noise is defined.
                              if isfield(s, 'noise_contrast') && ~isempty(s.noise_contrast)
                                  noise_frame = color_weight(frames(:,:,:,fi), s.color .* ex.disp.whitecolor);
                                  ct_texid = Screen('MakeTexture', ex.disp.winptr, uint8(noise_frame));
                                  src_rect_ct = [0 0 nx ny];
                              end
                              
                              % Restore alpha setting
                              Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 1 1 1]);
                               
                              % photodiode
                              if fi == 1
                                  if k < repeat_trigger_k
                                    pd = 0; % skip start screen trigger
                                    pdrect = ex.disp.pdrect;
                                  elseif k == repeat_trigger_k && kk == 1 % repeat trigger 
                                    pd = ex.disp.pd_color;
                                    pdrect = ex.disp.pdrect;
                                  else
                                    pd = ex.disp.pd_color;                % stim trigger 
                                    pdrect = ex.disp.pdrect2;
                                  end
                              else
                                  pd = 0;
                              end
                              %Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 1]);
                              Screen('FillOval', ex.disp.winptr, pd, pdrect);
                              %Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [s.color 1]);

                              % flip onto the screen
                              Screen('DrawingFinished', ex.disp.winptr);
                              vbl_old = vbl;
                              [vbl, ~, ~, missed] = Screen('Flip', ex.disp.winptr, vbl + stim_ifi - ex.disp.ifi/8.);
%                               if fi <4
%                                frame_interval = vbl - vbl_old;
%                               end
                             
                              if (missed > 0)
                                    % A negative value means that dead- lines have been satisfied.
                                    % Positive values indicate a deadline-miss.
                                    if (fi > 1)
                                        ex.disp.missed = ex.disp.missed + 1;
                                        if ex.debug == false % display only when it is not in debug mode
                                            fprintf('(stim repeats) frame index %d: flip missed = %f\n', fi, missed);
                                        end
                                    end
                              end
                              
                              % snapshot mode
                              if contains(ex_mode, 'snap') && fi == 1
                                  while ~ex.key.keycode(ex.key.space)
                                        % (JK comment) Assumption: keycode was initialized as zero vector. 
                                        % escape the loop by pressing space or esc
                                        ex = checkkb(ex);
                                  end
                                  ex.key.keycode(ex.key.space) = 0;   
                                  break;
                              end
                              
                              % check for ESC
                              ex = checkkb(ex);
                              if ex.key.keycode(ex.key.esc)
                                ex.stop_by_ESC = datestr(now, 'HH:MM:SS');
                                %fprintf('ESC pressed. Quitting.')
                                error('ESC pressed. Quitting.')
                              end
                             
                        end
                    end
                    
                    % close texture pointers for stim k
                    Screen('Close', ct_texid);
                    Screen('Close', bg_texid);
                end
                
            end
            ex.t_end = datestr(now, 'HH:MM:SS');
            ex.duration = ex.t_end - ex.t_start;
            ex.duration = etime(clock, t1); % secs
            fprintf('Total duration of stimulus was %.1f min (One repeat = %.1f secs).\n', ex.duration/60., ex.duration/ex.n_repeats);

            
          % Check for ESC keypress during the experiment
          ex = checkesc(ex);

          % Close windows and textures, clean up
          endexpt();
            
        % Save the experimental metadata
%         savejson('', ex, fullfile(basedir, 'expt.json'));
%         save(fullfile(basedir, 'exlog.mat'), 'ex');
        save(fullfile(basedir, [datestr(now, 'HH_MM_SS'), '_ex_', ex_name,'.mat']), 'ex');

        % Send results via Pushover
        sendexptresults(ex);

              
    % catch errors
    catch my_error

      % store the error
      ex.my_error = my_error;

      % display the error
      disp(my_error);
      struct2table(rmfield(ex.my_error.stack,'file'))

      % Close windows and textures, clean up
      endexpt();

      % Send results via Pushover
      if ~debug_exp
        %sendexptresults(ex);
      end
    end

end

function p = gen_checkers(nx, ny)
% Generate checkers composed of 0 and 1. 
    [x, y] = meshgrid(1:nx, 1:ny);
    p = mod(x+y, 2);
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

if ndims(A) ~= length(color)
    error('Color dimension mismatch');
end

C = zeros(size(A));

for c = 1:length(color)
    C(:,:,c) = A(:,:,c) * color(c);
end

end

function p =  ParseInput(varargin)
    
    p  = inputParser;   % Create an instance of the inputParser class.
    
    addParamValue(p,'framerate', 60, @(x)x>=0);
    addParamValue(p,'debug', false, @(x) islogical(x) || isnumeric(x));
    addParamValue(p,'title', '_', @(x) ischar(x));
    addParamValue(p,'mode', '', @(x) ischar(x));
%     addParamValue(p,'c_mask', [0 1 1], @(x) isvector(x));
%     addParamValue(p,'barColor', 'dark', @(x) strcmp(x,'dark') || ...
%         strcmp(x,'white'));
%      
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

