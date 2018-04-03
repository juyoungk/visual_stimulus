function ex = initdisp(ex, x0, y0, varargin)
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

% Feb 07 2018 - input arguments for offset position
%               Screen number search for lowest resolution

if nargin <2
    x0 = 0;
    y0 = 0;
elseif nargin <3
    y0 = 0;
    disp(['Stim Rect is offset by x0 = ', num2str(x0), ' um. No offset for y.']);
else
    disp(['Stim Rect is offset by x0 = ', num2str(x0), ' um, y0 = ', num2str(y0), ' um']);
end
ex.disp.offset_x_um = x0;
ex.disp.offset_y_um = y0;

% Make sure PTB is working, hide the on screen cursor
AssertOpenGL;

% Get the screen numer
%ex.disp.screen = max(Screen('Screens'));
n = length(Screen('Screens'));
resolutions = cell(1, n);
cur_display_Res_width = 100000000;
for i = 1:n
    resolutions{i} = Screen('resolution', i-1);
    if resolutions{i}.width < cur_display_Res_width
        cur_display_Res_width = resolutions{i}.width;
        % pick screen number whose resolution is the lowest among
        % others.
        ex.disp.screen = i-1;
    end
end
disp(['Screen number = ', num2str(ex.disp.screen)]);

% Colors
ex.disp.white = round(WhiteIndex(ex.disp.screen));
ex.disp.black = BlackIndex(ex.disp.screen);
ex.disp.gray  = round((ex.disp.white + ex.disp.black) / 2);

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
    rig_Name = 'test';                
     
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
    rig_Name = '2P_new_rig_Olympus_4x';
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
ex.disp.pix_per_100um = PIXELS_PER_100_MICRONS(rig_Name);

% the destination rectangle: size and offset
aperturesize = 2.4 % mm
ex.disp.aperturesize_mm = aperturesize;                 	% Size of stimulus aperture
ex.disp.aperturesize    = aperturesize*10*PIXELS_PER_100_MICRONS(rig_Name);                 	% Size of stimulus aperture
ex.disp.offset_x = (x0/100) * PIXELS_PER_100_MICRONS(rig_Name);
ex.disp.offset_y = (y0/100) * PIXELS_PER_100_MICRONS(rig_Name);
ex.disp.dstrect      = CenterRectOnPoint(...	% Stimulus destination rectangle
  [0 0 ex.disp.aperturesize ex.disp.aperturesize], ...
  ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y);

% missed flips
ex.disp.missedflips = [];
ex.disp.missed = 0;
end


function p =  ParseInput(varargin)
    
    p  = inputParser;   % Create an instance of the inputParser class.
    
    addParamValue(p,'N_repeat', 20, @(x)x>=0);
    addParamValue(p,'barWidth', 150, @(x)x>=0);
    addParamValue(p,'barSpeed', 1.4, @(x)x>=0);
    addParamValue(p,'c_channels', 2, @(x) ismatrix(x)); % index for color channesl. e.g. 2 or [2, 3]
    addParamValue(p,'c_mask', [0 1 1], @(x) isvector(x));
    addParamValue(p,'barColor', 'dark', @(x) strcmp(x,'dark') || ...
        strcmp(x,'white'));
     
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end
