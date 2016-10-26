function newlog = addlog(log, varargin)
% list should be char array
p = ParseInput(varargin{:});

s = dbstack('-completenames');
idx = length(s);
callingFunction = s(idx); 
    
info = sprintf('%s %12s \t %s', datestr(now), callingFunction.name, p.Results.LOG);
newlog = char(log, info);

end

function p = ParseInput(varargin)
    p  = inputParser;   % Create an instance of the inputParser class.
    text = [];
    
    % parameters
    p.addParameter('LOG', text, @(x) ischar(x));
    % 
    p.parse(varargin{:});
end