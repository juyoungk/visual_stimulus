function ex = initdisp(ex)
%
% FUNCTION ex = initdisp(ex)
%
% Initialize the display. 
%
% (c) bnaecker@stanford.edu 2014 
%     modified by nirum@stanford.edu 2015
%
% 27 Feb 2015 - added check for background color in 'ex' struct
% 28 Apr 2015 - removed check for alternate display

% Make sure PTB is working, hide the on screen cursor
AssertOpenGL;

% Get the screen numer
ex.disp.screen = max(Screen('Screens'));

% Colors
ex.disp.white = WhiteIndex(ex.disp.screen);
ex.disp.black = BlackIndex(ex.disp.screen);
ex.disp.gray  = (ex.disp.white + ex.disp.black) / 2;

% Check 'ex' struct for background color
if ~isfield(ex.disp, 'bgcol')
  ex.disp.bgcol = 127.5 .* ones(1, 3);
end

% Initialize the OpenGL pipeline, set debugging
InitializeMatlabOpenGL;

% Juyoung option 
ex.disp.nominal_frate = Screen('NominalFrameRate', ex.disp.screen);
if any([ex.disp.nominal_frate == 0, ex.disp.screen ==0, ex.debug==1])
    Screen('Preference', 'SkipSyncTests',1);
    Screen('Preference', 'VisualDebugLevel', 3);
    ex.disp.ifi=0.01176568031;
    %[ex.disp.w ex.disp.rect]=Screen('OpenWindow', ex.disp.screen, backColor, [10 10 1000 1000]);
    [ex.disp.winptr, ex.disp.winrect] = PsychImaging('OpenWindow', ...
                        ex.disp.screen, ex.disp.bgcol,[0 10 1024 778]);
else
    %HideCursor;
    Screen('Preference', 'VisualDebugLevel', 3);
    % Setup PsychImaging pipeline, allows for fast drawing
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
    % Open the window, fullscreen is default
    [ex.disp.winptr, ex.disp.winrect] = PsychImaging('OpenWindow', ...
  ex.disp.screen, ex.disp.bgcol);
end
oldtxtsize = Screen('TextSize', ex.disp.winptr, 10);

% Setup alpha-blending
Screen('BlendFunction', ex.disp.winptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Screen info
ex.disp.ifi    		= Screen('GetFlipInterval', ex.disp.winptr);
ex.disp.frate  		= round(1 / ex.disp.ifi);
ex.disp.nominalifi	= 1 / ex.disp.frate;
ex.disp.winctr 		= ex.disp.winrect(3:4) ./ 2;
ex.disp.info   		= Screen('GetWindowInfo', ex.disp.winptr);

% Set some text properties
Screen('TextFont', ex.disp.winptr, 'Helvetica');
Screen('TextSize', ex.disp.winptr, 24);

% Describe photodiode
ex.disp.pdscale = 0.9;					% Scale factor for the photodiode signal
ex.disp.pdctr   = [0.93 0.15];
ex.disp.pdsize  = SetRect(0, 0, 100, 100);
ex.disp.pdrect  = CenterRectOnPoint(ex.disp.pdsize, ...
  ex.disp.winrect(3) * ex.disp.pdctr(1), ...
  ex.disp.winrect(4) * ex.disp.pdctr(2));
% Juyoung PD setting
[ex.disp.pdrect, ex.disp.pd_color] = DefinePD_shift(ex.disp.winptr);

% Microns per pixel
ex.disp.umperpix = 100 / 4.7;
ex.disp.pix_per_100um = PIXELS_PER_100_MICRONS;

% the destination rectangle
aperturesize = 2.5 % mm
ex.disp.aperturesize = aperturesize*10*PIXELS_PER_100_MICRONS;                 	% Size of stimulus aperture
ex.disp.dstrect      = CenterRectOnPoint(...	% Stimulus destination rectangle
  [0 0 ex.disp.aperturesize ex.disp.aperturesize], ...
  ex.disp.winctr(1), ex.disp.winctr(2));

% missed flips
ex.disp.missedflips = [];
ex.disp.missed = 0;
