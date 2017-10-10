function vbl = diff_Grating_Screen(vbl0, w, screenRect, waitframes, ifi, white, black, ... 
           BG_visiblesize, Ct_visiblesize, gratingtexBg, gratingtexCt, masktex, ...
           barWidthPixels, shift_Ct, shift_Bg, speed, ...
           phase_init_Ct, phase_delay_Bg, period_Secs, N_periods, ...
           angleBG, angleCenter, w_Annulus, annu_Color, ...
           exp_name)
%
% Default sequence with phase=0 is [ 0 0 0 (no shift)... 1 1 1 (shift) ...].
%
% gratingtexBg, gratingtexCt: grating texture made by Screen('MakeTexture')
% gWavelengthPixels : wavelength of the one period of grating in pixels.
% shift_Ct, shift_Bg: amplitude of the shift (1 is 1 bar width)
    
    gray=round((white+black)/2);
    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if gray == white
      gray=white / 2;
    end
    inc=white-gray;
    [pd, pd_color_max] = DefinePD_shift(w);
    % Annulus for boundary between center and BG
    rectAnnul = CenterRect([0 0 Ct_visiblesize+2*w_Annulus Ct_visiblesize+2*w_Annulus], screenRect);

    %
    N_frames_Period = round(period_Secs/(waitframes*ifi)); % Num of frames over one step period = Num of phases
    N_frames = N_periods*N_frames_Period
    total_time = N_frames*waitframes*ifi % exactly 10s?
    id_half = round(N_frames_Period/2.);
    % speed of grating shift
    speed = speed * waitframes * ifi; % pixels/frame
    %speed_Bg = speed_Bg * waitframes * ifi;
    % frame number for the whold shift
    N_frames_shift_Ct = round(shift_Ct*barWidthPixels/speed);
    %N_frames_shift_Bg = round(shift_Bg*barWidthPixels/speed_Bg);
    %
    %max_shift_Ct = speed_Ct*N_frames_shift_Ct;
    %max_shift_Bg = speed_Bg*N_frames_shift_Bg;
    if N_frames_shift_Ct >= id_half
        error('too slow speed of grating shift');
    end
    
    % Center grating  
    phase_center = (1:N_frames_Period)>(N_frames_Period/2.);
    phase_center = double(phase_center);
    phase_center(id_half-N_frames_shift_Ct:id_half) = linspace(0,1,N_frames_shift_Ct+1);
    phase_center(end-N_frames_shift_Ct:end) = linspace(1,0,N_frames_shift_Ct+1);
    phase_center = circshift(phase_center(:), phase_init_Ct); % vectorization (:) for column vector
    % background
    phase_bg = phase_center;
    phase_bg = circshift(phase_bg, phase_delay_Bg); % phase delay of BG
    % shift sequences
    traj_Ct = round(phase_center * shift_Ct*barWidthPixels);
    traj_Bg = round(phase_bg * shift_Bg*barWidthPixels);
    
    % texture for visualizing phase delay
    tex_Ct = black + (white-black)*phase_center';
    tex_Bg = black + (white-black)*phase_bg'; % column vector
    x_square = numel(tex_Ct);
    y_square = 20; % pixels
    x_display = N_frames_Period*4;
    PhaseSq_Ct = Screen('MakeTexture', w, tex_Ct);
    PhaseSq_Bg = Screen('MakeTexture', w, tex_Bg);
    %
    cur_frame = 1; vbl = vbl0; secsPrev = 0;
    FLAG_BG_TEXTURE = 1; 
    %
    while (cur_frame <= N_frames)
        
        i_phase = mod(cur_frame, N_frames_Period)+1;
        
        xoffset_Ct = traj_Ct(i_phase);
        xoffset_Bg = traj_Bg(i_phase);
        
        % text display
        delay_msecs = phase_delay_Bg*waitframes*ifi*1000;
        if delay_msecs > period_Secs*1000
            delay_msecs = delay_msecs - period_Secs*1000;
        end
        frame_txt = ['[',num2str(floor(cur_frame./N_frames_Period)+1),'/',num2str(N_periods),' steps (period = ',num2str(period_Secs),'s)]'];
        text1 = ['delay time (relative to center) = ',num2str(delay_msecs,'% 5.0f'),' ms ',frame_txt];
        Screen('DrawText', w, exp_name, 10, 10, white);
        Screen('DrawText', w, text1, 10, 30, white);
        
        % Draw texture for phase visualization
        Screen('DrawTexture', w, PhaseSq_Ct, [0 0 x_square y_square], [10 50 10+x_display 50+y_square], 0);
        Screen('DrawTexture', w, PhaseSq_Bg, [0 0 x_square y_square], [10 54+y_square 10+x_display 54+2*y_square], 0);
        
        %
        % Definition of the drawn rectangle on the screen:
        dstRect=CenterRect([0 0 BG_visiblesize BG_visiblesize], screenRect);
        dst2Rect=CenterRect([0 0 Ct_visiblesize Ct_visiblesize], screenRect);
        % Define shifted srcRect that cuts out the properly shifted rectangular
        % area from the texture:
        % Jittered scrRect: subpart of the texture
        srcRect=[xoffset_Bg 0 xoffset_Bg + BG_visiblesize BG_visiblesize];
        src2Rect=[xoffset_Ct 0 xoffset_Ct + Ct_visiblesize Ct_visiblesize];
        
        % Draw BG grating texture, rotated by "angle":
        if FLAG_BG_TEXTURE
         Screen('DrawTexture', w, gratingtexBg, srcRect, dstRect, angleBG);
        end
        
        %if drawmask_BG==1
        if 1
            % Draw aperture (Oval) over grating:
            Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % Juyoung add
            Screen('DrawTexture', w, masktex, [0 0 BG_visiblesize BG_visiblesize], dstRect, angleBG);
        end;

        % annulus  
        Screen('FillOval', w, annu_Color, rectAnnul);

        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', w, GL_ONE, GL_ZERO, [0 0 0 1]);
        % Clear 'dstRect' region of framebuffers alpha channel to zero:
        Screen('FillRect', w, [0 0 0 0], dst2Rect);
        % Fill circular 'dstRect' region with an alpha value of 255:
        Screen('FillOval', w, [0 0 0 255], dst2Rect);

        % Enable DeSTination alpha blending and reenable drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        % Screen('Blendfunction', windowindex, [souce or new], [dest or
        % old], [colorMaskNew])
        Screen('Blendfunction', w, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
        % Draw 2nd grating texture, but only inside alpha == 255 circular
        % aperture, and at an angle of 90 degrees: Now the angle is 0
        Screen('DrawTexture', w, gratingtexCt, src2Rect, dst2Rect, angleCenter);
        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
           
        % photodiode
        Screen('FillOval', w, xoffset_Ct/0.5*pd_color_max, pd);
        if cur_frame ==1
            Screen('FillOval', w, pd_color_max, pd);
        end
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
        cur_frame = cur_frame + 1;
        
        %
        [keyIsDown, firstPress] = KbQueueCheck();
            if keyIsDown
                key = find(firstPress);
                secs = min(firstPress(key)); % time for the first pressed key
                if (secs - secsPrev) < 0.1
                    continue
                end

                switch key
                    case KbName('ESCAPE')
                        error(['Stop the stimulus by user during the following experiment : ', exp_name]);
                        break;             
                    case KbName('q')
                        error(['Stop the stimulus by user during the following experiment : ', exp_name]);
                        break;             
                    case KbName('j') % jitter
                        %FLAG_SimpleMove = 0;
                    case KbName('n') % next
                        break;
                    case KbName('RightArrow')
                        break;
                    case KbName('}]')
                        angleBG = angleBG + 45;
                    case KbName('{[')
                        angleBG = angleBG - 45;
                    case KbName('9(') % default setting
                        angleBG = angleBG + 90;    
                    case KbName('0)') % default setting
                        angleBG = 0;
                    case KbName('.>') % fine tuning of delay time
                        phase_delay_Bg = phase_delay_Bg + 1;
                    case KbName(',<')
                        phase_delay_Bg = phase_delay_Bg - 1;
                    case KbName('space')
                        FLAG_Global_Motion = ~FLAG_Global_Motion;
                        %phase_delay_Bg = (~phase_delay_Bg)*round(N_phase/2);
                    case KbName('UpArrow') 

                    case KbName('DownArrow')

                    case KbName('DELETE')
                        FLAG_BG_TEXTURE = ~FLAG_BG_TEXTURE;

                    case KbName('d') % debug mode
                        FLAG_debug = 1;

                    otherwise                    
                end
                secsPrev = secs;
            end

    end % while end

end
