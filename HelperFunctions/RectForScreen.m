function rect = RectForScreen(screen, Lx, Ly, centerX, centerY)
% Rect object in the screen
% centerX and centerY are offsets from the center of the screen. 
% (0,0) is the center of the screen.
% 20151019 Juyoung
rect = SetRect(0, 0, Lx, Ly);
rect = CenterRect(rect, screen.rect);
rect = OffsetRect(rect, centerX, centerY);
end