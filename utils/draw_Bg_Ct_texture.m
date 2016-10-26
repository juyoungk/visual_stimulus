function draw_Bg_Ct_texture(ex, Bg_tex, Ct_tex, Bg_masktex, D_Bg, D_Ct, Bg_shift, Ct_shift, angleBG)
%
% All units should be as pixels.
% Bg_tex and Ct_tex are texture indexes created by 'MakeTexture' in Screen.  
% Shift parameters can be either [x] or [x y]. 
% Annulus (Ct/Bg) is now commented.
%
% (c) Juyoung Kim 2016 1023
%
% s.window = ex.disp.winptr; s.screenRect = ex.disp.winrect; 
        %%
        angleCenter = 0;
        if nargin < 9
            angleBG = 0;
        end;
        if nargin < 8
            Ct_shift = [];
        end;
        if nargin < 7
            Bg_shift = [];
        end;
        %%
        Bg_shift = round(Bg_shift);
        Ct_shift = round(Ct_shift);
        %%
        switch length(Bg_shift)
            case 0
                Bg_xshift = 0;
                Bg_yshift = 0;
            case 1
                Bg_xshift = Bg_shift;
                Bg_yshift = 0;
            case 2
                Bg_xshift = Bg_shift(1);
                Bg_yshift = Bg_shift(2);
            otherwise
                error('Bg_shift is not properly defined.');
        end
       
        switch length(Ct_shift)
            case 0 
                Ct_xshift = 0;
                Ct_yshift = 0;
            case 1
                Ct_xshift = Ct_shift;
                Ct_yshift = 0;
            case 2
                Ct_xshift = Ct_shift(1);
                Ct_yshift = Ct_shift(2);
            otherwise
                error('Ct_shift is not properly defined.');
        end
        
        %% Dst Rects: Final rectangles on the screen
        dstRect_Bg = CenterRect([0 0 D_Bg D_Bg], ex.disp.winrect);
        dstRect_Ct = CenterRect([0 0 D_Ct D_Ct], ex.disp.winrect);
        
        %% Source Rects = Size of Dst Rects, but with offset: Define the subpart of the texture 
        % only effective when the shift parameters are given.
        % Original texture object should be larger than the size of scrRect
        % due to random the shift.
        srcRect_Bg = [Bg_xshift Bg_yshift D_Bg+Bg_xshift D_Bg+Bg_yshift];
        srcRect_Ct = [Ct_xshift Ct_yshift D_Ct+Ct_xshift D_Ct+Ct_yshift];
        
        %% Draw BG grating texture
        if isempty(Bg_shift)
            Screen('DrawTexture', ex.disp.winptr, Bg_tex, [], dstRect_Bg, angleBG);
        else
            Screen('DrawTexture', ex.disp.winptr, Bg_tex, srcRect_Bg, dstRect_Bg, angleBG);
        end
        
        %%
        % Draw BG Mask (or aperture)
        Screen('Blendfunction', ex.disp.winptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % Juyoung add
        Screen('DrawTexture', ex.disp.winptr, Bg_masktex, [0 0 D_Bg D_Bg], dstRect_Bg, angleBG);
        
        % annulus  
        %Screen('FillOval', ex.disp.winptr, annu_Color, rectAnnul);
        
        %%
        % Disable alpha-blending, restrict following drawing to alpha channel:
        Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [0 0 0 1]);
        % Clear 'dstRect' region of framebuffers alpha channel to zero:
        %Screen('FillRect', ex.disp.winptr, [0 0 0 0], dstRect_Ct);
        Screen('FillRect', ex.disp.winptr, [0 0 0 0], dstRect_Bg);
        % Fill circular 'dstRect' region with an alpha value of 255:
        Screen('FillOval', ex.disp.winptr, [0 0 0 255], dstRect_Ct);

        % Enable DeSTination alpha blending and reenable drawing to all
        % color channels. Following drawing commands will only draw there
        % the alpha value in the framebuffer is greater than zero, ie., in
        % our case, inside the circular 'dst2Rect' aperture where alpha has
        % been set to 255 by our 'FillOval' command:
        % Screen('Blendfunction', windowindex, [souce or new], [dest or
        % old], [colorMaskNew])
        Screen('Blendfunction', ex.disp.winptr, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);
        
        %%
        % Draw 2nd (Center) texture, but only inside alpha == 255 circular
        % aperture, and at an angle of 90 degrees: Now the angle is 0
%         if isempty(Ct_shift)
%             Screen('DrawTexture', ex.disp.winptr, Ct_tex, [], dstRect_Ct, angleCenter);
%         else 
%             Screen('DrawTexture', ex.disp.winptr, Ct_tex, srcRect_Ct, dstRect_Ct, angleCenter);
%         end
        Screen('DrawTexture', ex.disp.winptr, Ct_tex, srcRect_Ct, dstRect_Ct, angleCenter);
        
        % Restore alpha blending mode for next draw iteration:
        Screen('Blendfunction', ex.disp.winptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


end

