function ex = speed_discrimination(ex, replay)
% One grating at the center, Natural images (or the other grating) at the background
%
% Modified from DriftDemo5(angle, cyclespersecond, f, drawmask)
% Modified from OMS_SimpleMove
% Modified from OMS_diff_motion_phase_scan 10/03/2016 Juyoung

commandwindow % Change focus to command window
me = ex.stim{end}.params;
%
addpath(me.imgdir)
s.window = ex.disp.winptr; s.screenRect = ex.disp.winrect; 
s.color.gray = ex.disp.gray;

% initialize random seed
if isfield(me, 'seed')
  rs = getrng(me.seed);
else
  rs = getrng();
end
%ex.stim{end}.seed = rs.Seed;

%% jumpevery and sessions
StimSize_Ct = 800; % um
StimSize_BG = 3.5; % mm
w_gratingbar = me.w_gratingbar; % um; Grating Bar; 2*Bar = 1 period; ~RF size of BP
w_Annulus = w_gratingbar;
n_session = 3;
n_repeat = me.n_repeat;
jumpevery = me.jumpevery;
contrast = linspace(me.contrast(1), me.contrast(2), me.contrast(3));
%
d_speed = linspace(me.d_speed(1), me.d_speed(2), me.d_speed(3)); % drift speed. um/second. 0 = global motion
bg_speedseq = me.bg_speed;
speed = Pixel_for_Micron(d_speed);
bg_speedseq = Pixel_for_Micron(bg_speedseq);
speedseq = [1:length(speed)];
% 
numframes = jumpevery * n_session * n_repeat * length(speedseq) * length(bg_speedseq) * length(w_gratingbar) * length(contrast);
% save info at ex struct
ex.stim{end}.params.numframes = numframes;
ex.stim{end}.params.runtime_secs = numframes * ex.disp.ifi;    
ex.stim{end}.params.speedidxseq = speedseq;
ex.stim{end}.params.d_speedseq = d_speed(speedseq);
if isfield(ex, 'runtime_secs')
    ex.runtime_secs = ex.runtime_secs + ex.stim{end}.params.runtime_secs;
else
    ex.runtime_secs = ex.stim{end}.params.runtime_secs;
end

%%
w_Annulus = Pixel_for_Micron(w_Annulus);
rBg = Pixel_for_Micron(StimSize_BG*1000/2.); % radius of the Bg image
rCt = Pixel_for_Micron(StimSize_Ct/2.);      % radius of the Ct image
barWidthPixels = Pixel_for_Micron(w_gratingbar);

%% Natural image setting
L_patch_Bg = me.ndims;
L_patch_Ct = round(StimSize_Ct/(StimSize_BG*1000)*L_patch_Bg); % pixel number for the image @ Center
% Scale bar for the image: 1 pixel of the stimulus = ? pixels in the image

%%
period = 2*barWidthPixels; % pixels /one cycle (= wavelength) ~2*Bipolar cell RF
f = 1./period;    % Grating cycles/pixel; spatial phase velocity
fr= f*2*pi;   % phase per one pixel
if me.naturalscenes
    period = 0;
end
%%
% darken the photodiode
Screen('FillOval', ex.disp.winptr, 0, ex.disp.pdrect);
ex.disp.vbl = Screen('Flip', ex.disp.winptr);
%try
    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
    white = ex.disp.white;
    black = ex.disp.black;
     gray = ex.disp.gray;
    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if ex.disp.gray == ex.disp.white
      ex.disp.gray = ex.disp.white /2;
    end
    
    %% load natural images 
    files = dir(fullfile(me.imgdir, me.imgext));
    numimages = length(files);
    images = cell(numimages, 1);
    for fileidx = 1:numimages
        images(fileidx) = struct2cell(load(fullfile(me.imgdir, files(fileidx).name)));
    end
        
    %% Drifting grating (@ Center)
    % Calculate parameters of the grating:
    Bg_size = 2*rBg + 1;
    Ct_size = 2*rCt + 1; % center texture size?

    %% Mask texture id for Bg
    mask = ones(2*rBg+1, 2*rBg+1, 2) * ex.disp.bgcol; % Why 2 layers? LA (Luminance + Alpha)
    [x, y] = meshgrid(-1*rBg:1*rBg,-1*rBg:1*rBg);
    % Gaussian profile can be introduced at the 1st Luminance layer.
    mask(:, :, 2) = white * (1-(x.^2 + y.^2 <= rBg^2));
    masktex = Screen('MakeTexture', s.window, mask);
        
    %% display the params 
    ex_params = ex.stim{end}.params
    
    %% Loop over exp conditions
    for c = 1:length(contrast)
    for p = period
        %%
        % drifting length over one session (not saccade)
        shiftperframe = speed(speedseq) * me.waitframes * ex.disp.ifi; % pixels per one stim frame
        max_driftL = max(shiftperframe) * jumpevery;
        max_driftLimg = max_driftL * (L_patch_Bg(1)/Bg_size);

        %% Grating texture ids
        % BG
        [x ,~]=meshgrid(-rBg:rBg + p, 1);
        [x2,~]=meshgrid(-rCt:rCt + p, 1);
        grating_BG = 2*mod(floor(x/(0.5*p)),2)*contrast(c) + (1-contrast(c));
        grating_Ct = 2*mod(floor(x2/(0.5*p)),2)*contrast(c) + (1-contrast(c));
        Bg_gratingtex = Screen('MakeTexture', s.window, ex.disp.gray*grating_BG);
        Ct_gratingtex = Screen('MakeTexture', s.window, ex.disp.gray*grating_Ct);

        % Null (bgcol uniform. Not gray)
        gray_tex = Screen('MakeTexture', s.window, ex.disp.gray); % Single value. No pattern at Bg
        
        %%
        for j = 1:length(bg_speedseq)
        for i = 1:length(speedseq)
            %% display drifting velocity
            speed_idx = speedseq(i);
            cur_speed = speed(speed_idx);         % speed = pixels/second
            bg_speed = bg_speedseq(j);
            cur_shiftperframe = shiftperframe(i); % pixels per 1 frame
                %%
                for k = 1:n_repeat
                    %%
                    text1 = sprintf('speed = %.0f um/s (%d/%d) ', d_speed(speed_idx), i, length(speedseq));
                    text = [text1];
                    %%
                    ex.disp.vbl=GetSecs();
                    %%
                        %% Grating                       
                        %offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size,      gray_tex,      gray_tex, [], 'Bg_drift',        0, 'Ct_drift',        0, 'offset',     {}, 'pd_trigger',     white, 'period', p, 'masktex', masktex, 'text', text);
                        
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, [], 'Bg_drift', 0, 'Ct_drift',         0, 'offset',     {}, 'pd_trigger', white, 'period', p, 'masktex', masktex, 'text', text);
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, [], 'Bg_drift', 0, 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.4*white, 'period', p, 'masktex', masktex, 'text', text);
                        % How Bg motion affect the neural coding of the
                        % object
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, [], 'Bg_drift',        0, 'Ct_drift',         0, 'offset',    {}, 'pd_trigger', 0.7*white, 'period', p, 'masktex', masktex, 'text', text);
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, [], 'Bg_drift', bg_speed, 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.4*white, 'period', p, 'masktex', masktex, 'text', text);

                            offset{1} = offset{1} + [p/2. 0];    
                            offset{2} = offset{2} + [p/2. 0];
                                          
                    
                end % repeat over same condition
        end % loop over Ct speed
        end % loop over bg speed

    end % loop over grating periods
    end % loop over exp conditions (e.g. contrast)

%catch    
%     KbQueueFlush(device_id(1));
%     KbQueueStop(device_id(1));
%end

end