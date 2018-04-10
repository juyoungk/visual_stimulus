function ex = stims_repeat(stim, n_repeats)
% gap between center and bg: 0.2mm
    if nargin < 2
        n_repeats = 5;
    end
    debug_exp = false;
    % default conditions
    gray_margin = 0.2;
    framerate = 30;
    stim_ifi = 1/framerate;
    
    addpath('utils/')
    commandwindow
    try
        
          % Construct an experimental structure array
          ex = initexptstruct(debug_exp);
          % Initialize the keyboard
          ex = initkb(ex);
          % bg color & margin
          ex.disp.bgcol = 0;
          
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
         
          % initialize the VBL timestamp
          vbl = GetSecs();
          fi =1;
            for i = 1:n_repeats

                for k = 1:numStim
                    % current stim
                    s = stim(k);
                    if isempty(s.ndims)
                        continue;
                    end
                    % dims
                    L = s.sizeCenter * 1000 * ex.disp.pix_per_um;
                    L_gray = (s.sizeCenter + gray_margin)*1000*ex.disp.pix_per_um;
                    %
                    nx = s.ndims(1);      
                    ny = s.ndims(2);
                    checkers_center = gen_checkers(nx+1, ny+1);
                    checkers_center = color_matrix(checkers_center, s.color);
                    
                    % make the texture
                    ct_texid = Screen('MakeTexture', ex.disp.winptr, uint8(ex.disp.white * checkers_center));
                    
                    % dst rect for center
                    ct_dst_rect = CenterRectOnPoint(...	
                              [0 0 L L], ...
                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y);
                    % gray dst rect
                    gray_rect = CenterRectOnPoint(...	
                              [0 0 L_gray L_gray], ...
                              ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y);
                    
                    % BG checkers
                    width_x = s.sizeCenter/nx;
                    width_y = s.sizeCenter/ny;
                    if nx == 1
                        nx_bg = 1;
                    else
                        nx_bg = ex.disp.aperturesize_mm/width_x;      
                    end
                    if ny == 1
                        ny_bg =1;
                    else
                        ny_bg = ex.disp.aperturesize_mm/width_y;
                    end
                    checkers_bg = gen_checkers(nx_bg+1, ny_bg+1);
                    checkers_bg = color_matrix(checkers_bg, s.color);
                    %if s.BG     
                        bg_texid = Screen('MakeTexture', ex.disp.winptr, uint8(ex.disp.white * checkers_bg));
                    %end
%                           % write_mask
%                           c_mask = stim(k).c_mask;
%                           if ~replay
%                             Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);
%                           end
                    for kk =1:s.cycle
                        
                        frames_per_period = round(framerate * s.half_period * 2); % phase step;
                        shift_ct = 1:frames_per_period > (round(frames_per_period/2.));
                        shift_bg = circshift(shift_ct, round(s.delay*frames_per_period));
                        
                        for fi = 1:frames_per_period 
                              
                              if nx > 1
                                  src_rect_bg = [shift_bg(fi) 0 nx_bg + shift_bg(fi)  ny_bg];
                                  src_rect_ct = [shift_ct(fi) 0    nx + shift_ct(fi)  ny   ];
                              else
                                  src_rect_bg = [0 shift_bg(fi) nx_bg  ny_bg + shift_bg(fi)];
                                  src_rect_ct = [0 shift_ct(fi) nx     ny    + shift_ct(fi)];
                              end
                              
                              % draw the texture, then kill it
                              if s.BG
                                  Screen('DrawTexture', ex.disp.winptr, bg_texid, src_rect_bg, ex.disp.dstrect, 0, 0);
                                  Screen('FillRect',    ex.disp.winptr, ex.disp.gray*s.color, gray_rect);
                              end
                              Screen('DrawTexture', ex.disp.winptr, ct_texid, src_rect_ct, ct_dst_rect, 0, 0);
                              %Screen('DrawTexture', ex.disp.winptr, ct_texid, [], ct_dst_rect, 0, 0);

                              % photodiode
                              if fi == 1
                                  pd = ex.disp.pd_color;
                              else
                                  pd = 0;
                              end
                              %Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 1]);
                              Screen('FillOval', ex.disp.winptr, pd, ex.disp.pdrect);
                              %Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [s.color 1]);

                              % flip onto the scren
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
            ex.duration = ex.end - ex.start
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
    [x, y] = meshgrid(1:nx, 1:ny);
    p = mod(x+y+1, 2);
end

function C = color_matrix(A, color)
% color as a weight vector, form a 3D color matrix from 2D matrix A.
n = numel(color);

C = zeros([size(A), n]);

for c = 1:n
    C(:,:,c) = color(c) * A(:,:);
end

end
