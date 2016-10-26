function offset = diff_motion_session(ex, numframes, Bg_size, Ct_size, Bg_tex, Ct_tex, jitter, varargin)
%
% jitter = {Bg Ct}. [Bg] (or [Ct]) should be a sequence which has a size of
% [numframes, 2].
% drift : along x direction only. pixels/ms
% 'waitframes' & 'ifi' should be defined at the stim parameters of the ex object.
% (e.g. ex.stim{end}.params.waitframes)
% 
p = inputParser;
p.addParamValue('Bg_drift', 0, @(x) isnumeric(x) && isscalar(x)); % drift speed. (pixels per second)
p.addParamValue('Ct_drift', 0, @(x) isnumeric(x) && isscalar(x));
p.addParamValue('offset', {[0 0],[0 0]}, @(x) iscell(x)); % offset = {[Bg], [Ct]}
p.addParamValue('pd_trigger', ex.disp.white, @(x) isnumeric(x) && isscalar(x));
p.addParamValue('masktex', []);
p.addParamValue('period', 0, @(x) isnumeric(x) && isscalar(x));
p.addParamValue('text', [], @(x) ischar(x));
p.parse(varargin{:});
%
Bg_drift = p.Results.Bg_drift;
Ct_drift = p.Results.Ct_drift;
 offset  = p.Results.offset;
pd_trigger = p.Results.pd_trigger;
masktex = p.Results.masktex;
period = p.Results.period;
text = p.Results.text;

% no jitter?
if isempty(jitter)
    jitter{1} = zeros(numframes, 2);
    jitter{2} = zeros(numframes, 2);
end

% jitter sequence check
if any([~isequal(size(jitter{1}), [numframes, 2]), ~isequal(size(jitter{2}), [numframes, 2])])
    error('Invalid jitter sequence.');
end
%
if any([length(offset{1}) ~= 2, length(offset{2}) ~= 2])
    error('Invalid data types for the offset');
end
%

waitframes = ex.stim{end}.params.waitframes;
ifi = ex.disp.ifi;
vbl = ex.disp.vbl;
pdrect = ex.disp.pdrect;
Ct_shiftperframe = Ct_drift * waitframes * ifi;
Bg_shiftperframe = Bg_drift * waitframes * ifi;

for cur_frame = 1:numframes
    % drift (object or bg)
        offset{1} = offset{1} + [Bg_shiftperframe 0];
        offset{2} = offset{2} + [Ct_shiftperframe 0];
    
    % jitter followed by 'mod' operation
        offset{1} = offset{1} + jitter{1}(cur_frame, :); 
        offset{2} = offset{2} + jitter{2}(cur_frame, :); 
        
    % mod operation for periodic pattern
        offset{1} = mod(offset{1}, period); 
        offset{2} = mod(offset{2}, period); 
        
    % draw
    draw_Bg_Ct_texture(ex, Bg_tex, Ct_tex, masktex, Bg_size, Ct_size, offset{1}, offset{2});
    
    % PD
    if cur_frame == 1
        Screen('FillOval', ex.disp.winptr, pd_trigger, pdrect);
    end
    
    % text
    if ~isempty(text)
        Screen('DrawText', ex.disp.winptr, text, 20, 20, ex.disp.gray);
    end

    % flip        
    vbl = Screen('Flip', ex.disp.winptr, vbl + (waitframes - 0.5) * ifi);
    
    % Keyboard check
    if KbCheck(-1)
        %break;
        error('!Stop by user.');
    end
end
ex.disp.vbl = vbl;

end