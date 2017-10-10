function log = WaitStartKey(w, varargin)
% WaitStartKey(w); w is window
% WaitStartKey(w, expName); w is window
%
p = ParseInput(varargin{:});

screenNumber=max(Screen('Screens'));
% Find the color values which correspond to white and black.
white=WhiteIndex(screenNumber);
black=BlackIndex(screenNumber);
% Round gray to integral number, to avoid roundoff artifacts with some
% graphics cards:
gray=round((white+black)/2);
% This makes sure that on floating point framebuffers we still get a
% well defined gray. It isn't strictly neccessary in this demo:
if gray == white
  gray=white / 2;
end
[windowSizeX, windowSizeY] = Screen('WindowSize', w);

%
%pd = DefinePD(w);
[pd, pd_color] = DefinePD_shift(w);

text = ['Press any key to start'];
expName = [date, ' ', p.Results.expName];

Screen('FillOval', w, black, pd); % first PD: black
Screen('DrawText', w, text, 0.45*windowSizeX, 0.42*windowSizeY, white);
Screen('DrawText', w, expName, 0.3*windowSizeX, 0.38*windowSizeY, white);

Screen('Flip', w, 0);

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
%if YorN==KbName('space'), WaitForRec; end;

% last screen before stimulus
Screen('FillOval', w, black, pd); % first PD: black
Screen('Flip', w, 0);
pause(1);

log = [datestr(now), '  ', p.Results.expName];

end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.
    text = 'experiment';
    
    % Gabor parameters
    addParamValue(p,'expName', text, @(x) ischar(x));
    % 
    p.parse(varargin{:});
end