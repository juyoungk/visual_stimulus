function testscreen

commandwindow
screen = InitScreen(0, 1024, 768, 85);

    boxL_um = 50; %unit: um
    boxL = Pixel_for_Micron(boxL_um);  %um to pixels
    disp(['Pixel N for ', num2str(boxL_um), 'um =  ', num2str(boxL), ' px']);
    disp(['Pixel N for ', num2str(100), 'um =  ', num2str(PIXELS_PER_100_MICRONS), ' px']);
    
    N = 31; % determines the stim size
    stimsize = boxL*N;
    % 3-2. MEA Box (150um = MEA length = 30 * 5)
    boxL_ref = 7*PIXELS_PER_100_MICRONS;
    
 % Define the obj Destination Rectangle
objRect = RectForScreen(screen,stimsize,stimsize,0,0);

 for i=1:20
    Screen('FillRect', screen.w, screen.gray);
    objColor = ( rand(N, N)>.5)*2*screen.gray;
    % objColor = rand(5, 1)*screen.white;

    % 1. random texture pointer
    objTex  = Screen('MakeTexture', screen.w, objColor);
    % display last texture
    Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);
    Screen('FillOval', screen.w, screen.white, DefinePD);
    Screen('Flip', screen.w, 0);
    % pause until Keyboard pressed
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    % 27 is 'esc'
    if YorN==27, break; end;
    
    %
    % 2. checker
    %
    Screen('FillRect', screen.w, screen.gray);
    [x, y] = meshgrid(1:N, 1:N);
    objColor = mod(x+y,2)*2*screen.gray;
    % texture pointer
    objTex  = Screen('MakeTexture', screen.w, objColor);
    % display last texture
    Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);
    Screen('FillOval', screen.w, screen.white, DefinePD);
     %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect]
    %[,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [,
    %modulateColor] [, textureShader] [, specialFlags] [, auxParameters]);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end;
    
    % 3-1. One Box
    box =  RectForScreen(screen,boxL,boxL,0, 0);
    Screen('FillRect', screen.w, screen.gray);
    Screen('FillRect', screen.w, screen.black, box);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end;
    
    % 3-2. MEA Box
    box =  RectForScreen(screen, boxL_ref, boxL_ref, 0, 0);
    Screen('FillRect', screen.w, screen.gray);
    Screen('FillRect', screen.w, screen.black, box);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end;
    
    % Stim area
    box =  RectForScreen(screen,stimsize,stimsize,0, 0);
    Screen('FillRect', screen.w, screen.black);
    Screen('FillRect', screen.w, screen.white, box);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end;
    
    % black screen
    Screen('FillRect', screen.w, screen.black);
    Screen('Flip', screen.w, 0);
    
    % pause until Keyboard pressed
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end;
end

Screen('CloseAll');

end