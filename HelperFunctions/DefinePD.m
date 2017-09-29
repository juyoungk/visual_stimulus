function pd = DefinePD(varargin)
% returns Rec dimension; pd = [left,top,right,bottom]
% size? 1 mm in visual field. 10*PIXELS_PER_100_MICRONS
    
    nVarargs = length(varargin);
    if nVarargs >= 1
        w = varargin{1};
        [windowSizeX, windowSizeY] = Screen('WindowSize', w);
    else
        [windowSizeX, windowSizeY] = Screen('WindowSize', max(Screen('Screens')));
    end
    
    pd = SetRect(0,0, windowSizeY*.16, windowSizeY*.16);
    pd = CenterRectOnPoint(pd, windowSizeX*.93, windowSizeY*.15);
    
    %Add2StimLogList();
end
