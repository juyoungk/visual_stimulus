function [a1, a2] = GetCheckers(Nx, Ny, checkersWidth, contrast, mean)
% GetCheckers(Nx, Ny, checkersWidth, contrast, mean)
% Nx = Column numbers; Ny = row numbers
% if Nx or Ny =1, it will give a grating
    Add2StimLogList();
    [x, y]  = meshgrid(0:Nx-1, 0:Ny-1);
    x = mod(floor(x/checkersWidth),2);
    y = mod(floor(y/checkersWidth),2);
    checkers = x.*y + ~x.*~y;
    a1 = checkers*2*mean*contrast + mean*(1-contrast);
    a2 = (~checkers)*2*mean*contrast + mean*(1-contrast);
end

