function screen = testscreen_annulus(debug, intensity_factor)
% intensity calibration? max duty rate (= max intensity)
% scan intensity
commandwindow % Change focus to command window
addpath('HelperFunctions/')
addpath('functions/')

if nargin == 0 
    debug =0;
    intensity_factor = 1;
elseif nargin == 1
    intensity_factor = 1;
end

% box Param
boxL_um = 250;        
boxL    = Pixel_for_Micron(boxL_um); %unit: um
     N  = 5; % determines the stim size
%               
commandwindow;
addpath('HelperFunctions/')
% don't care the sync test for color test
Screen('Preference', 'SkipSyncTests',1);
screen = InitScreen(debug);
disp(['screen.white = ',num2str(screen.white)]);
disp(['screen.black = ',num2str(screen.black)]);

%
vbl =0;
ifi = screen.ifi;
device_id = MyKbQueueInit; % paired with "KbQueueFlush()"
secsPrev = 0;
FLAG_annulus = true;
c_array = eye(3);
c = 3;

while true
       
    stimsize = max(0, (N+1) * boxL);
    box     = RectForScreen(screen,stimsize, stimsize,0,0);
    stimsize = max(0, (N-1) * boxL);
    box_in     = RectForScreen(screen, stimsize, stimsize, 0, 0);
    
    % color mask
    c_mask = c_array(c,:);
    Screen('Blendfunction', screen.w, GL_ONE, GL_ZERO, [c_mask 1]);
    %
    Screen('FillOval', screen.w, screen.white, box);
    if FLAG_annulus
        Screen('FillOval', screen.w, screen.black, box_in);
    end
    
    vbl = Screen('Flip', screen.w, vbl+ifi*0.5);
    
    %Keyboard input
%     KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
%     if YorN==27, break; end
%     
    [keyIsDown, firstPress] = KbQueueCheck();
            if keyIsDown
                key = find(firstPress);
                secs = min(firstPress(key)); % time for the first pressed key
                if (secs - secsPrev) < 0.1
                    continue
                end

                switch key
                    case KbName('ESCAPE')
                        break;
                    case KbName('q')
                        break;
                    
                    case KbName('RightArrow')
                        N = N +1;
                    case KbName('LeftArrow')
                        N = N -1;
                    case KbName('9(') % default setting
                        
                    case KbName('0)') % default setting
                        
                    case KbName('.>')
                        
                    case KbName(',<')
                        
                    case KbName('space')
                        FLAG_annulus = ~ FLAG_annulus;
                    case KbName('UpArrow') 
                        c = mod((c + 1),3)+1;
                        
                    case KbName('DownArrow')
                        c = mod((c - 1),3)+1;
                    otherwise                    
                end
                secsPrev = secs;
            end
end    
            
            
% for i=1:1        
%             
%     % 1. Stim area (0 intensity outside of the stim area)     
%     % color change @ white intensity
%         for j=1:n_colors
%             % bright stim area on dark
%             Screen('FillRect', screen.w, 0);
%             Screen('FillRect', screen.w, color_sequence{j}, box);
%             Screen('FillOval', screen.w, color_sequence{j}, pd);
%             vbl = Screen('Flip', screen.w, vbl+ifi*0.5);
%             KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
%             if YorN==27, break; end
%         end
%         
%     % 2. texture (Is there a chromatic abberation ?)
%     [x, y] = meshgrid(1:N, 1:N);
%     texMatrix = max(min(mod(x+y,2)*2*screen.gray, 255), 0);
%     objTex  = Screen('MakeTexture', screen.w, texMatrix);
%     angle = 0;
%     % color change @ white intensity
%         for j=1:n_colors
%             % bright stim area on dark
%             Screen('FillRect', screen.w, 0);
%             Screen('DrawTexture', screen.w, objTex, [], objRect, angle, 0, 1, color_sequence{j});
%             Screen('FillOval', screen.w, pd_color, pd);
%             vbl = Screen('Flip', screen.w, vbl+ifi*0.5);
%             KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
%             if YorN==27, break; end
%         end
%               
%         
%         
%  end

Screen('CloseAll');
KbQueueStop(device_id(1));

end