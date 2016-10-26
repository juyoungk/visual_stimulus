function log = WaitStartKeyTrigger(screen, varargin)
% text string
% posX, poY in pixels
p = ParseInput(screen, varargin{:});
pd = DefinePD;
text = ['Press any key to start (space key for external trigger)'];

Screen('FillOval', screen.w, screen.black, pd); % first PD: black
% Screen('DrawText', screen.w, text, 0.6*screen.sizeX, p.Results.posY-15, screen.white);
% Screen('DrawText', screen.w, p.Results.TEXT, p.Results.posX, p.Results.posY, screen.white);

Screen('Flip', screen.w, 0);

KbName('UnifyKeyNames');
% Keyboard start or wait for an external trigger
KbWait(-1, 2); 
% 'deviceNumber' = -1 --> all keyboards
%      'forwhat' = 2 --> wait until all keys are released, 
%                       then for the first keypress, then it will return.
[~, ~, c]=KbCheck;
YorN=find(c); keybuffer = max(vec(c));
% flush the buffer
while ( keybuffer )
    [~, ~, c]=KbCheck;
    keybuffer = max(vec(c));
end
if YorN==KbName('space'), WaitForRec; end;

% last screen before stimulus
Screen('FillOval', screen.w, screen.black, pd); % first PD: black
Screen('Flip', screen.w, 0);
pause(1);

log = [datestr(now), '  ', p.Results.TEXT];

end

function p = ParseInput(screen, varargin)
    p  = inputParser;   % Create an instance of the inputParser class.
    text = date;
    
    % Gabor parameters
    p.addParamValue('posX', 0.75*screen.sizeX, @(x) x>=0 && x<screen.sizeX);
    p.addParameter('posY', 20, @(x) x>=0 && x<screen.sizeY);
    p.addParameter('TEXT', text, @(x) ischar(x));
    % 
    p.parse(varargin{:});
end