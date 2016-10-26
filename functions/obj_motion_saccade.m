function ex = obj_motion_saccade(ex, replay)
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
BarWidth = 50; % um; Grating Bar; 2*Bar = 1 period; ~RF size of BP
w_Annulus = BarWidth;
n_session = 8;
n_jitter  = me.n_jitter; % num of different jitter sequences
n_repeat = me.n_repeat;
jumpevery = me.jumpevery;
contrast = linspace(me.contrast(1), me.contrast(2), me.contrast(3));
%
d_speed = linspace(me.d_speed(1), me.d_speed(2), me.d_speed(3)); % drift speed. um/second. 0 = global motion
speed = Pixel_for_Micron(d_speed);
speedseq = [randperm(rs, length(speed))];
% 
numframes = jumpevery * n_session * n_jitter * n_repeat * length(speedseq) * length(contrast);
% save info at ex struct
ex.stim{end}.params.numframes = numframes;
ex.stim{end}.params.runtime_secs = numframes * ex.disp.ifi;    
ex.stim{end}.params.speedseq = speedseq;
ex.stim{end}.params.d_speed = d_speed(speedseq);
%
jitteramp = me.jitteramp;

%%
w_Annulus = Pixel_for_Micron(w_Annulus);
rBg = Pixel_for_Micron(StimSize_BG*1000/2.); % radius of the Bg image
rCt = Pixel_for_Micron(StimSize_Ct/2.);      % radius of the Ct image
barWidthPixels = Pixel_for_Micron(BarWidth);

%% Natural image setting
L_patch_Bg = me.ndims;
L_patch_Ct = round(StimSize_Ct/(StimSize_BG*1000)*L_patch_Bg); % pixel number for the image @ Center
% Scale bar for the image: 1 pixel of the stimulus = ? pixels in the image

%%
p = 2*barWidthPixels; % pixels /one cycle (= wavelength) ~2*Bipolar cell RF
f = 1./p;    % Grating cycles/pixel; spatial phase velocity
fr= f*2*pi;   % phase per one pixel

%%
% darken the photodiode
Screen('FillOval', ex.disp.winptr, 0, ex.disp.pdrect);
ex.disp.vbl = Screen('Flip', ex.disp.winptr);
try
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
    
    %% Generate a full sequence of jitters (estimate max shift). 2 sessions long.
    % n different sequence
    jitter_Bg = (randi(rs, (2*jitteramp+1), 2*jumpevery, 2, n_jitter) - (jitteramp+1));
    jitter_Ct = (randi(rs, (2*jitteramp+1), 2*jumpevery, 2, n_jitter) - (jitteramp+1));
    % Only jitter (not drifting nor saccade) is coherent for Bg and Ct.
    if me.global
        jitter_Bg = jitter_Ct;
    end
    % Amount of shift by jitter: Accumulation
    shift_Bg = cumsum(jitter_Bg);
    shift_Ct = cumsum(jitter_Ct);
    % Set min to zero
    minshift_Bg = min(shift_Bg(:));
    minshift_Ct = min(shift_Ct(:));
    % amplitude of shift
    ampshift_Bg = max(shift_Bg(:)) - minshift_Bg;
    ampshift_Ct = max(shift_Ct(:)) - minshift_Ct;
    % Estimate the shift in the orginal image
    maxshift_BgImg = ceil(L_patch_Bg/Bg_size) * ampshift_Bg;
    maxshift_CtImg = ceil(L_patch_Bg/Bg_size) * ampshift_Ct;

    
    %% display the params 
    ex_params = ex.stim{end}.params
    
    %% Loop over exp conditions
    for c = 1:length(contrast)
        %%
        % drifting length over one session (not saccade)
        shiftperframe = speed(speedseq) * me.waitframes * ex.disp.ifi; % pixels per one stim frame
        max_driftL = max(shiftperframe) * jumpevery;
        max_driftLimg = max_driftL * (L_patch_Bg(1)/Bg_size);

        %% texture ids from object and Bg images
        tex_size_Bg = [Bg_size + ampshift_Bg, Bg_size + ampshift_Bg];
        tex_size_Ct = [Ct_size + ampshift_Ct, Ct_size + ampshift_Ct]; % [x y]
        tex_Nat_Bg1  = texFromImages(ex, images{3}, L_patch_Bg + maxshift_BgImg, tex_size_Bg, contrast(c), rs);
        tex_Nat_Bg2  = texFromImages(ex, images{7}, L_patch_Bg + maxshift_BgImg, tex_size_Bg, contrast(c), rs);
        tex_Nat_Ct1 = texFromImages(ex, images{5}, L_patch_Ct + maxshift_CtImg + [max_driftLimg 0], tex_size_Ct + [max_driftL 0], contrast(c), rs);
        tex_Nat_Ct2 = texFromImages(ex, images{6}, L_patch_Ct + maxshift_CtImg + [max_driftLimg 0], tex_size_Ct + [max_driftL 0], contrast(c), rs);

        %% Grating texture ids
        % BG
        [x ,~]=meshgrid(-rBg:rBg + p, 1);
        [x2,~]=meshgrid(-rCt:rCt + p, 1);
        grating_BG = 2*mod(floor(x/(0.5*p)),2)*contrast(c) + (1-contrast(c));
        grating_Ct = 2*mod(floor(x2/(0.5*p)),2)*contrast(c) + (1-contrast(c));
        Bg_gratingtex = Screen('MakeTexture', s.window, ex.disp.gray*grating_BG);
        Ct_gratingtex = Screen('MakeTexture', s.window, ex.disp.gray*grating_Ct);

        % Null (bgcol uniform. Not gray)
        gray_tex = Screen('MakeTexture', s.window, ex.disp.bgcol); % Single value. No pattern at Bg
        
        %%
        for i = 1:length(speedseq)
            %% display drifting velocity
            speed_idx = speedseq(i);
            cur_speed = speed(speed_idx);         % speed = pixels/second
            cur_shiftperframe = shiftperframe(i) % pixels per 1 frame
            %%
            for j = 1:n_jitter
                %%
                if me.imgshuffle
                    tex_Nat_Bg1  = texFromImages(ex, images, L_patch_Bg + maxshift_BgImg, tex_size_Bg, contrast(c), rs);
                    tex_Nat_Bg2  = texFromImages(ex, images, L_patch_Bg + maxshift_BgImg, tex_size_Bg, contrast(c), rs);
                    tex_Nat_Ct1 = texFromImages(ex, images, L_patch_Ct + maxshift_CtImg + [max_driftLimg 0], tex_size_Ct + [max_driftL 0], contrast(c), rs);
                    tex_Nat_Ct2 = texFromImages(ex, images, L_patch_Ct + maxshift_CtImg + [max_driftLimg 0], tex_size_Ct + [max_driftL 0], contrast(c), rs);
                end
                %%
                for k = 1:n_repeat
                    %%
                    offset_Bg = [0 0] - minshift_Bg;    
                    offset_Ct = [0 0] - minshift_Ct;
                    jitter1obj = { zeros(jumpevery,2), jitter_Ct(1:jumpevery,:,j)     };
                    jitter2obj = { zeros(jumpevery,2), jitter_Ct(jumpevery+1:end,:,j) };
                    jitter1 = { jitter_Bg(1:jumpevery,:,j),     jitter_Ct(1:jumpevery,:,j)     };
                    jitter2 = { jitter_Bg(jumpevery+1:end,:,j), jitter_Ct(jumpevery+1:end,:,j) };
                    text1 = sprintf('speed = %.0f um/s (%d/%d) ', d_speed(speed_idx), i, length(speedseq));
                    text2 = sprintf('[%d/%d jitter]-%d/%d repeats', j, n_jitter, k, n_repeat);
                    text = [text1, text2];
                    %%
                    ex.disp.vbl=GetSecs();
                    %%
                    if me.naturalscenes
                        % No jitter
                        offset = {offset_Bg, offset_Ct};
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, tex_Nat_Bg1, tex_Nat_Ct1, [], 'Ct_drift',         0, 'offset', offset, 'pd_trigger', 0.9*white, 'masktex', masktex, 'text', text);
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, tex_Nat_Bg1, tex_Nat_Ct2, [], 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.6*white, 'masktex', masktex, 'text', text);
                        % New jittered obj w/o Bg
                        offset = {offset_Bg, offset_Ct};
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, tex_Nat_Bg1, tex_Nat_Ct1, jitter1obj, 'Ct_drift',         0, 'offset', offset, 'pd_trigger', 0.6*white, 'masktex', masktex, 'text', text);
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, tex_Nat_Bg1, tex_Nat_Ct2, jitter2obj, 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.3*white, 'masktex', masktex, 'text', text);
                        % New jittered obj w/ Bg jitter but w/o saccade
                        offset = {offset_Bg, offset_Ct};
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, tex_Nat_Bg1, tex_Nat_Ct1, jitter1, 'Ct_drift',         0, 'offset', offset, 'pd_trigger', 0.3*white, 'masktex', masktex, 'text', text);
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, tex_Nat_Bg1, tex_Nat_Ct2, jitter2, 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.3*white, 'masktex', masktex, 'text', text);
                        % New jittered obj w/ Bg jitter also w/ saccade
                        offset = {offset_Bg, offset_Ct};
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, tex_Nat_Bg1, tex_Nat_Ct1, jitter1, 'Ct_drift',         0, 'offset', offset, 'pd_trigger', 0.3*white, 'masktex', masktex, 'text', text);
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, tex_Nat_Bg2, tex_Nat_Ct2, jitter2, 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.3*white, 'masktex', masktex, 'text', text);
                    else
                        % No jitter
                        offset = {offset_Bg, offset_Ct};
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, [], 'Ct_drift',         0, 'offset', offset, 'pd_trigger', 0.9*white, 'period', p, 'masktex', masktex, 'text', text);
                            offset{2} = offset{2} + [p/2. 0];
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, [], 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.3*white, 'period', p, 'masktex', masktex, 'text', text);
                        % New obj w/o Bg
                        offset = {offset_Bg, offset_Ct};
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, jitter1obj, 'Ct_drift',         0, 'offset', offset, 'pd_trigger', 0.6*white, 'period', p, 'masktex', masktex, 'text', text);
                            offset{2} = offset{2} + [p/2. 0];
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, jitter2obj, 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.3*white, 'period', p, 'masktex', masktex, 'text', text);
                        % New obj w/o Bg jump
                        offset = {offset_Bg, offset_Ct};
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, jitter1, 'Ct_drift',         0, 'offset', offset, 'pd_trigger', 0.3*white, 'period', p, 'masktex', masktex, 'text', text);
                            offset{2} = offset{2} + [p/2. 0];
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, jitter2, 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.3*white, 'period', p, 'masktex', masktex, 'text', text);
                        % New obj w/  New Bg jump also
                        offset = {offset_Bg, offset_Ct};
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, jitter1, 'Ct_drift',         0, 'offset', offset, 'pd_trigger', 0.3*white, 'period', p, 'masktex', masktex, 'text', text);
                            offset{1} = offset{1} + [p/2. 0];    
                            offset{2} = offset{2} + [p/2. 0];
                        offset = diff_motion_session(ex, jumpevery, Bg_size, Ct_size, Bg_gratingtex, Ct_gratingtex, jitter2, 'Ct_drift', cur_speed, 'offset', offset, 'pd_trigger', 0.3*white, 'period', p, 'masktex', masktex, 'text', text);
                    end
                    
                end % repeat over same jitter sequence
            end % loop over jitter sequences

        end % loop over speeds

    end % loop over exp conditions (e.g. contrast)

catch    
%     KbQueueFlush(device_id(1));
%     KbQueueStop(device_id(1));
end

end