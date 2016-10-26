function newlog = addLog(log, varargin)
% list should be char array
p = ParseInput(varargin{:});

s = dbstack('-completenames');
if length(s)>1
    idx = 2;
else
    idx = 1;
end
callingFunction = s(idx); 
% inputParser object
parameter = p.Results.pInputParser;
duration = p.Results.duration;

if (duration == 0)
    info = sprintf('%s                %24s\t%s', datestr(now), callingFunction.name, p.Results.LOG);
else
    info = sprintf('%s duration=%5.2f %24s\t%s', datestr(now), duration, callingFunction.name, p.Results.LOG);
end
newlog = char(log, info);

    if ~isempty(parameter)
        newlog = char(newlog, '   List of parameters');
        newlog = char(newlog, parameter.Results);
    end

end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.
    text = [];
    parameter = [];
    
    % parameters
    p.addParameter('LOG', text, @(x) ischar(x));
    p.addParameter('duration', 0.00, @(x) x>=0);
    p.addParameter('pInputParser', parameter);
    % 
    p.parse(varargin{:});
end