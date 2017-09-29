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
    
    % upright scope PD (0928 2017 Juyoung)
 
    pd = SetRect(0,0, windowSizeY*.08, windowSizeY*.08);
    pd = CenterRect(pd, screen.rect);
    
    % shift from center.
    pd_shift = 1000; % um
    
    x = Pixel_for_Micron(pd_shift);
    pd = OffsetRect(pd, x, x);
    
    %Add2StimLogList();
end
