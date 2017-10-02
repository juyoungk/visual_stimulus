function pd = DefinePD_shift(w, varargin)
    
    % upright scope PD (0928 2017 Juyoung)

    p = ParseInput(varargin{:});

    pd_shift = p.Results.shift; 
    pd_size = p.Results.size;
    [x_window, y_window] = Screen('WindowSize', w);
    
    x = Pixel_for_Micron(pd_shift);
    pd_size = Pixel_for_Micron(pd_size);
 
    pd = SetRect(0,0, pd_size, pd_size);
    pd = CenterRect(pd, [0,0,x_window, y_window]);
    pd = OffsetRect(pd, x, x);

end

function p =  ParseInput(varargin)
    
    p  = inputParser;   % Create an instance of the inputParser class.
    
    addParamValue(p,'shift', 2000, @(x)x>=0); % um
    addParamValue(p,'size', 400, @(x)x>=0); % um
    
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
