function ex = stims_repeat(stim, n_repeats, varargin)
% noise: uniformly-distributed whitenoise only. ndims = 3 only.
% gap between center and bg: 0.2mm
    p = ParseInput(varargin{:});
    if nargin < 2
        n_repeats = 3
    end
    debug_exp = p.Results.debug;
    ex_title = p.Results.title;
    % default conditions
    gray_margin = 0.2;
    framerate = p.Results.framerate;
    stim_ifi = 1/framerate;
    
    addpath('utils/')
    commandwindow
    try
          % id for FOV or Exp.
          loc_id = input(['\nNEW EXPERIMENT: ', ex_title, '\nFOV or Loc name? (e.g. 1 or 2 ..) ']); 
          [stim(:).name] = deal(['loc',loc_id, '_', ex_title]);
            
          % Construct an experimental structure array
          ex = initexptstruct(debug_exp);
          % Initialize the keyboard
          ex = initkb(ex);
          
          % Initalize the visual display w/ offset position
          ex = initdisp(ex, 1500, -100);
          % wait for trigger
          ex = waitForTrigger(ex);
          
          % save stim info
          numStim = numel(stim);
          ex.stim = cell(1,numStim);
          for e=1:numStim
            ex.stim{e} = stim(e);
            ex.stim{e}.framerate = framerate;
          end
          ex.n_repeats = n_repeats;
            
          % initialize the VBL timestamp
          vbl = GetSecs();
          
            for i = 1:n_repeats

                for k = 1:numStim % current stim
                    
                    s = stim(k);
                    if isempty(s.ndims)
                        continue;
                    end
                    % frame numbers
                    frames_per_period = round(framerate * s.half_period * 2);
                    
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
                    L = s.sizeCenter * 1000 * ex.disp.pix_per_um;
                    L_gray = (s.sizeCenter + gray_margin)*1000*ex.disp.pix_per_um;
                    
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
                    %
                    nx = s.ndims(1);
                    ny = s.ndims(2);
                    % dim+1 checkers
                    checkers_center = gen_checkers(nx+1, ny+1); % 0 and 1 checkers
                    checkers_center = color_matrix(checkers_center, s.color .* ex.disp.whitecolor);
                    
                    % make the texture
                    ct_texid = Screen('MakeTexture', ex.disp.winptr, uint8(checkers_center));
                    
                    % texture dst rect (integer times checkers)
                    w_pixels_x = ceil(L/nx);
                    w_pixels_y = ceil(L/ny);
                    Lx = w_pixels_x * nx;
                    Ly = w_pixels_y * ny;
                    Lchecker = max(Lx, Ly);
                    % display for grating stim
                    if any(s.ndims > [1, 1])
                        fprintf('(Grating stimulus) Pixels per one checker: [%d, %d]\n', w_pixels_x, w_pixels_y);  
                    end
                    ct_checker_rect = CenterRectOnPoint(...	
                              [0 0 Lchecker Lchecker], ...
                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y); 
                    
                    % dst rect for center
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
                    
                    for kk =1:s.cycle
                        
                        % phase for impulse (default for flashes)
                        if all(s.ndims == [1 1])
                            shift_ct = 0.5 * ones(1, frames_per_period);
                            shift_ct(1:2) = 0;                   % 2 frames = 1/15 sec for 30Hz presentation.
                            fi_ON = round(frames_per_period/2.); % frame id for pahse = 1 
                            shift_ct([fi_ON, fi_ON+1]) = 1;
                        else
                            % phase for step (duty rate 50%):
                            shift_ct = 1:frames_per_period > (round(frames_per_period/2.));
                        end
                        
                        shift_bg = circshift(shift_ct, round(s.delay*frames_per_period));
                        
                        % phase of the annulus: flashing vs moving
                        if length(L_ann) == 2 % [a, b]: moving anuulus
                            ann_phase = ones(1, frames_per_period);
                        else % single annulus: flashing
                            ann_phase = shift_ct; % same as center object
                            ann_phase = circshift(ann_phase, round(s.delay*frames_per_period)); % flashing annulus
                        end
                        
                        for fi = 1:frames_per_period 
                              
                              % bg color for entire presentation field.
                              Screen('FillRect', ex.disp.winptr, ex.disp.bgcol, ex.disp.winrect);
                            
                              if nx > 1
                                  src_rect_bg = [shift_bg(fi) 0 nx_bg + shift_bg(fi)  ny_bg];
                                  src_rect_ct = [shift_ct(fi) 0    nx + shift_ct(fi)  ny   ];
                              else
                                  src_rect_bg = [0 shift_bg(fi) nx_bg  ny_bg + shift_bg(fi)];
                                  src_rect_ct = [0 shift_ct(fi) nx     ny    + shift_ct(fi)];
                              end
                              
                              % draw the BG texture & gray gap
                              if isfield(s, 'BG') && ~isempty(s.BG) && s.BG
                                  Screen('DrawTexture', ex.disp.winptr, bg_texid, src_rect_bg, bg_dst_rect, 0, 0);
                                  Screen('FillRect',    ex.disp.winptr, ex.disp.bgcol, gray_rect); % margin rect.
                              end
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
                                Screen('FillOval', ex.disp.winptr, [0 0 0 ex.disp.white], ct_dst_rect);  
                                %
                                Screen('Blendfunction', ex.disp.winptr, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
                              
                              if isfield(s, 'noise_contrast') && ~isempty(s.noise_contrast)
                                  noise_frame = color_weight(frames(:,:,:,fi), s.color .* ex.disp.whitecolor);
                                  ct_texid = Screen('MakeTexture', ex.disp.winptr, uint8(noise_frame));
                                  src_rect_ct = [0 0 nx ny];
                              end
                                
                              % Draw center pattern
                              %if all(s.ndims == [1,1]) && (shift_ct(fi) == 0.5)
                              if shift_ct(fi) == 0.5 % 0.5 phase shift means gray or bg color. 
                                Screen('FillRect', ex.disp.winptr, ex.disp.bgcol, ct_checker_rect);  
                              else
                                Screen('DrawTexture', ex.disp.winptr, ct_texid, src_rect_ct, ct_checker_rect, 0, 0);
                              end
                              % Restore alpha setting
                              Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 1 1 1]);
                               
                              % photodiode
                              if fi == 1
                                  pd = ex.disp.pd_color;
                              else
                                  pd = 0;
                              end
                              %Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 1]);
                              Screen('FillOval', ex.disp.winptr, pd, ex.disp.pdrect);
                              %Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [s.color 1]);

                              % flip onto the screen
                              Screen('DrawingFinished', ex.disp.winptr);
                              [vbl, ~, ~, missed] = Screen('Flip', ex.disp.winptr, vbl + stim_ifi - ex.disp.ifi/2.);
                              
                              if (missed > 0)
                                    % A negative value means that dead- lines have been satisfied.
                                    % Positive values indicate a deadline-miss.
                                    if (fi > 1)
                                        fprintf('(stim repeats) frame index %d: flip missed = %f\n', fi, missed);
                                        ex.disp.missed = ex.disp.missed + 1;
                                    end
                              end

                              % check for ESC
                              ex = checkkb(ex);
                              if ex.key.keycode(ex.key.esc)
                                ex.stop_by_ESC = datestr(now, 'HH:MM:SS');
                                %fprintf('ESC pressed. Quitting.')
                                error('ESC pressed. Quitting.')
                                break;
                              end
                              
                        end
                    end
                    
                    % close texture pointers for stim k
                    Screen('Close', ct_texid);
                    Screen('Close', bg_texid);
                end
                
            end
            ex.end = datestr(now, 'HH:MM:SS');
            ex.duration = ex.end - ex.t_start;
            %disp(['Total duration of stimulus was ', num2str(ex.duration), ' secs']);
            
          % Check for ESC keypress during the experiment
          ex = checkesc(ex);

          % Close windows and textures, clean up
          endexpt();
            
        % Save the experimental metadata
%         savejson('', ex, fullfile(basedir, 'expt.json'));
%         save(fullfile(basedir, 'exlog.mat'), 'ex');

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
    
    addParamValue(p,'framerate', 30, @(x)x>=0);
    addParamValue(p,'debug', false, @(x) islogical(x));
    addParamValue(p,'title', '_', @(x) ischar(x));
%     addParamValue(p,'c_mask', [0 1 1], @(x) isvector(x));
%     addParamValue(p,'barColor', 'dark', @(x) strcmp(x,'dark') || ...
%         strcmp(x,'white'));
%      
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

