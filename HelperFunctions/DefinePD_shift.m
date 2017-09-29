function pd = DefinePD_shift(screen, varargin)
    
    %nVarargs = length(varargin);
    nVarargs = numel(varargin);
    if nVarargs < 2
        pd_shift = 1400 ; %um
    end
    
    % upright scope PD (0928 2017 Juyoung)
 
    pd = SetRect(0,0, screen.sizeX*.08, screen.sizeY*.08);
    pd = CenterRect(pd, screen.rect);
    
    x = Pixel_for_Micron(pd_shift);
    pd = OffsetRect(pd, x, x);

end
