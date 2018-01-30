function stim = RF_Juyoung(varargin)
    % !!! current checkerboard size is fixed at power of 2: 64
    % if you want to change a parameter from its default value you have to
    % type 'paramToChange', newValue, ...
    % List of possible params is:
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl
    commandwindow
    
    p = ParseInput(varargin{:});
    debug = p.Results.debug;
    objContrast = p.Results.objContrast;
    seed  = p.Results.seed;
    DurationSecs = p.Results.movieDurationSecs;
    stimFrameInterval = p.Results.stimFrameInterval;
    frameRateNominal = p.Results.frameRateNominal;
    % um to pixels 
        stimSize = Pixel_for_Micron( p.Results.stimSizeXYum);
    checkerSizeX = Pixel_for_Micron( p.Results.checkerSizeXum);
    checkerSizeY = Pixel_for_Micron( p.Results.checkerSizeYum);
    % 
    waitframes = p.Results.waitframes;
    objCenterXY = p.Results.objCenterXY;
    noise.type = p.Results.noiseType;
    c_channels = p.Results.c_channels;
    array_type = p.Results.array_type;
    %dispRes = p.Results.DisplayRes;
    %dispRate = p.Results.DisplayRate;
    stim = []; log = [];
try
    checkersN_H = ceil(p.Results.stimSizeXYum(1)/p.Results.checkerSizeXum);
    checkersN_V = ceil(p.Results.stimSizeXYum(2)/p.Results.checkerSizeYum);
  
    %screen = InitScreen(0, dispRes(1), dispRes(2), dispRate);
    screen = InitScreen(debug);
    % whiteFrames = round(screen.rate/waitframes); % # of stim flip for 1s
    % (defined by Pablo)
    % screen.rate = NominalFrameRate (Hz)
    framesPerFlip = round( stimFrameInterval/screen.ifi ); % = waitframes
    % Nominal-rate-optimized stimulus flip interval (not rate)
    frameTime = screen.ifi * framesPerFlip;
    framesN = uint32( round( DurationSecs / frameTime ));
    fprintf('framesN (juyoung) = %d\n', framesN);
    fprintf('Nominal-rate-optimaized RF stimulus flip interval (juyoung) = %.8f\n', frameTime);
    fprintf('Number of norminal frames per RF stimulus flip (or waitframes) = %d\n', framesPerFlip);
    % init random seed generator
    randomStream = RandStream('mcg16807', 'Seed', seed);
    % DefinePD returns the Rect dimension matrix; pd=newRect=[left,top,right,bottom];
    [pd, pd_color_max] = DefinePD_shift(screen.w);
    
    
    if strcmp(p.Results.recreation, 'yes')
        stim = RandomCheckersRecreate(framesN, checkersN_V, checkersN_H, objContrast, randomStream, noise);
    else        
        % Define the obj Destination Rectangle
        % set the size > center it > offset from the center
        objRect = SetRect(0,0,checkersN_H*checkerSizeX,checkersN_V*checkerSizeY);
        objRect = CenterRect(objRect, screen.rect);
        objRect = OffsetRect(objRect, objCenterXY(1), objCenterXY(2));
        %
        %WaitStartKeyTrigger(screen, 'TEXT', 'white noise checkerboard', 'posX', 0.60*screen.sizeX);
        WaitStartKey(screen.w, 'expName', 'White Noise Checkerboard');
        % Animationloop: draws Checker and PD and flip   
        [vbl, log] = RandomCheckers(screen, framesN, framesPerFlip, checkersN_V, checkersN_H, objContrast, randomStream, c_channels, pd, pd_color_max, objRect, noise, array_type);
        %[vbl, log] = RandomCheckers(screen, framesN, framesPerFlip, 64, 64, objContrast, randomStream, pd, pd_color_max, objRect, noise, array_type);
    end
%     
%     % gray screen
%     Screen('FillRect', screen.w, screen.gray/4);
%     Screen('Flip', screen.w, 0);
%     % pause until Keyboard pressed
%     KbWait(-1, 2); 
%     %[~, ~, c]=KbCheck;  YorN=find(c);
    
    %
    disp(log);
    Screen('CloseAll');
    Priority(0);
    ShowCursor();
    % Display parameters:
    disp 'List of all arguments:';
    disp(p.Results);
    fprintf('Nominal-rate-optimaized flip interval (juyoung) = %.8f\n', frameTime);
    fprintf('Number of norminal frames per RF stimulus flip = %d\n', framesPerFlip);
    logstr = char( ...
        ['Checker box X size in pixels: ',num2str(checkerSizeX)], ...
        ['Checker box Y size in pixels: ',num2str(checkerSizeY)], ...
        ['Actual stim size in pixels: ',num2str(checkersN_H*checkerSizeX),[' '],num2str(checkersN_V*checkerSizeY)] );
    disp(logstr);
    %add_experiments_to_db(start_t, vbls, varargin)
        
catch exception
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    CleanAfterError();
    rethrow(exception);
end %try..catch..
end

function [vbls, log] = RandomCheckers(screen, framesN, waitframes, checkersV, checkersH, ...
    objContrast, randomStream, c_mask, pd, pd_color_max, objRect, noise, array_type)
    
log = addLog([]);
cur_frame = 0;    %current frame number
screen.vbl = GetSecs();

%imgMat = zeros(checkersV, checkersH, 3);
    
    for frame = 0:framesN-1
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [c_mask 1]);
        %Screen('FillRect', screen.w, screen.gray);
        %Screen('FillRect', screen.w, screen.black);
        % Make a new obj texture
        % Generate random texture one frame by one frame
        % including color channels (2017 1110 Juyoung)
        if (strcmp(noise.type, 'binary'))
            objColor = (rand(randomStream, checkersV, checkersH, 3)>.5)*2*screen.gray*objContrast...
                + screen.gray*(1-objContrast);
        elseif (strcmp(noise.type, 'gaussian'))
           %objColor = randn(randomStream, checkersV, checkersH)
            objColor = randn(randomStream, checkersV, checkersH, 3)*screen.gray*.15 ...
                + screen.gray;
        end
        % assign white noise texture to color channels.
%             %imgMat(:,:,2) = objColor(:,:,2);
%             imgMat(:,:,c_channels) = objColor(:,:,c_channels);

        %objTex  = Screen('MakeTexture', screen.w, imgMat, [] , 1);
        objTex  = Screen('MakeTexture', screen.w, objColor);
        
        % display last texture
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0);
        
        % We have to discard the noise checkTexture.
        Screen('Close', objTex);
        
        % Draw the PD box (Red Channel)
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [1 0 0 1]);
            %color = objColor(1,1)/2*pd_color_max;%+screen.gray/2;
            %Screen('FillOval', screen.w, color, pd);
            if cur_frame==0
                Screen('FillOval', screen.w, pd_color_max, pd);
            elseif mod(cur_frame, 10) == 0
                Screen('FillOval', screen.w, pd_color_max/2, pd);
            end
        Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [c_mask 1]);
        
        % uncomment this line to check the coordinates of the 1st checker
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        %screen.vbl = Screen('Flip', screen.w, screen.vbl + (waitframes-.5) * screen.ifi);
        [screen.vbl, ~, ~, missed] = Screen('Flip', screen.w, screen.vbl + (waitframes - 0.5) * screen.ifi);
        if (missed > 0)
            % 'Negative' value means that deadlines have been satisfied. (good)
            % Positive values indicate a deadline-miss. (bad)
            if (cur_frame > 0)
                fprintf('(Checker) cur_frame = %d, (flip) missed = %f\n', cur_frame, missed);
            end
        end
        
        cur_frame = cur_frame + 1;
        
        if ~exist('vbls', 'var')
            vbls = screen.vbl;
        end
        
        if (KbCheck)
            break
        end
    end
    vbls(2) = screen.vbl;
end


% Juyoung added for recreation as bin file.
function [stim] = RandomCheckersRecreate(framesN, checkersV, checkersH, ...
    objContrast, randomStream, noise)
    % input for David's recording app should be 'uint8'?
    stim = zeros(checkersV, checkersH, framesN);
    
    for frame = 1:framesN
        if (strcmp(noise.type, 'binary'));
            objColor = rand(randomStream, checkersV, checkersH)>.5;
            %objColor = (rand(randomStream, checkersV, checkersH)>.5)*2*gray*objContrast...
            %    + gray*(1-objContrast);
        elseif (strcmp(noise.type, 'gaussian'))
            objColor = randn(randomStream, checkersV, checkersH)*gray*.15 ...
                + gray;
        end
        stim(:,:,frame) = objColor;
    end
    %saveasbin(stim);
end

function p =  ParseInput(varargin)
    % Generates a structure with all the parameters
    % Allowed parameters are:
    %
    % objContrast, objJitterPeriod, objSeed, stimSize, objSizeH, objSizeV,
    % objCenterXY, backContrast, backJitterPeriod, presentationLength,
    % movieDurationSecs, pdStim, debugging, barsWidth, waitframes, vbl

    % In order to get a parameter back just use
    %   p.Resulst.parameter
    % In order to display all the parameters use
    %   disp 'List of all arguments:'
    %   disp(p.Results)
    %
    % General format to add inputs is...
    % p.addRequired('script', @ischar);
    % p.addOptional('format', 'html', ...
    %     @(x)any(strcmpi(x,{'html','ppt','xml','latex'})));
    % p.addParamValue('outputDir', pwd, @ischar);
    % p.addParamValue('maxHeight', [], @(x)x>0 && mod(x,1)==0);
    p  = inputParser;   % Create an instance of the inputParser class.
    % framerate is same as screen.rate
    frameRate = Screen('NominalFrameRate', max(Screen('Screens')));
         % ifi = Screen('GetFlipInterval', screen.w);
    if frameRate==0
        frameRate=100;
    end
    
    %addParamValue(p,'DisplayRes', [1024,768], @(x) length(x)==2);
    %addParamValue(p,'DisplayRate', 85, @(x) x>=30);
    addParamValue(p,'debug', 0, @(x) x>=0 && x<=1);
    addParamValue(p,'objContrast', 1, @(x) x>=0 && x<=1);
    addParamValue(p,'seed', 1, @(x) isnumeric(x));
    %
    addParamValue(p,'movieDurationSecs', 60*20, @(x)x>0); % 30 min
    % Checker Size = 50 um (= 25 px in 2P rig with 25x Leica)
    addParamValue(p,'checkerSizeXum', 60, @(x) x>0); % um
    addParamValue(p,'checkerSizeYum', 60, @(x) x>0); % um
    % Stim Size = 1.0 mm (= 20 checkers)
    addParamValue(p,'stimSizeXYum', 2400*[1 1], @(x) all(size(x)==[1 2]) && all(x>0));
    %
    addParamValue(p,'frameRateNominal', frameRate, @(x)x>=0);
    %addParamValue(p,'stimFrameInterval', 0.03322955, @(x)x>=0);
    addParamValue(p,'stimFrameInterval', 0.03529554, @(x)x>=0);
    addParamValue(p,'waitframes', round(0.03322955*frameRate), @(x)isnumeric(x)); 
    addParamValue(p,'objCenterXY', [0 0], @(x) all(size(x) == [1 2]));
    addParamValue(p,'debugging', 0, @(x)x>=0 && x <=1);
    addParamValue(p,'pdStim', 0, @(x) isnumeric(x));
    addParamValue(p,'noiseType', 'binary', @(x) strcmp(x,'binary') || ...
        strcmp(x,'gaussian'));
    addParamValue(p,'c_channels', [0 1 1], @(x) ismatrix(x)); % index for color channesl. e.g. 2 or [2, 3]
    addParamValue(p,'array_type', 'HiDens_v3', @(x) ischar(x));   % in what units?
    addParamValue(p,'recreation', 'no', @(x) strcmp(x,'yes') || ...
        strcmp(x,'no'));
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end

