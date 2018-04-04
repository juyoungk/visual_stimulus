%% Color matching functions: CIE standard observer
M = csvread('ciexyz31.csv');
%%
cmf = M(:, 2:4);
wavelength = M(:,1);
plot(wavelength, cmf);
%% [r g b] to [0 U G(by 460)]
% UV-cone = B + R * 
%  M-cone = g + R * 
R = cmf(:, 1);
G = cmf(:, 2);
B = cmf(:, 3);
%
R_proj_B = R.'*B/norm(R)/norm(B);
R_proj_G = R.'*G/norm(R)/norm(G);

%% Open Movie file
mpath = '/Users/peterfish/Movies';
vid = VideoReader('Bee_Honet.mp4');
%vid = VideoReader('Falcon_catch.mp4');

%%
vidHeight = vid.Height;
vidWidth = vid.Width;
tot_numFrame = vid.Duration * vid.FrameRate;

% NOTE: why struct for each frame? Very convinient to append frames. No need
% to carefully match dimensions. 

mov = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),...
'colormap',[]);

% Define the 1st struct object. Then, the field (e.g. 'colormap') will continue even for
% appended object.

%% 
numFrame = 1000;
k = 1;
while hasFrame(vid)
    mov(k).cdata = readFrame(vid);
    
%     minFrame = min(mov(k).cdata(:))
%     maxFrame = max(mov(k).cdata(:))

    if k == numFrame
        break;
    end
    
    k = k+1;
end

%% Color adjust for Mouse cones.
% My projector: R-UV-B
numFrame = numel(mov);
mov2 = mov;
mm = zeros(numFrame, vidHeight, vidWidth, 3, 'uint8');

for k=1:numFrame
    % Convert to 16-bit integer in case that the sum can be over 255.
    cdata = uint16(mov2(k).cdata);
    w_color = zeros(1, 3);
        
    % Projection of R channel into B & G spectra
    p_blue = cdata(:,:,3) + R_proj_B * cdata(:,:,1);
    p_green = cdata(:,:,2) + R_proj_G * cdata(:,:,1);
  
    % 2nd LED ch (385 nm): Exciting S-opsin = B + 0.255*R
        % Sensitivity of S-cone to 385? ~ 50%
        % Sensitivity of M-cone to 385? ~ 20%
        % 385 would naturally excite both cones.
        
    % Normalization? Ratio btw B and G should be maintained.
    cdata(:,:,2) = p_blue/(1+R_proj_B);
    cdata(:,:,3) = p_green/(1+R_proj_G);
    % 3nd LED ch (460 nm): Exciting M-opsin = G + 0.760*R
    % Sensitivity of M-cone to 460? ~ 60%
    
    % Red Channel
    cdata(:,:,1) = 0;
    mov2(k).cdata = uint8(cdata);
    
    % 4-D structure?
    mm(k, :, :, :) = cdata;
end
%%
save([mpath,'/mov_bee.mat'], 'mm');

%% Play the movie (movie(M,n,fps))
hfig = figure('Position', [950, 550, 560, 420]);
    hfig.Color = 'none';
    hfig.PaperPositionMode = 'auto';
    hfig.InvertHardcopy = 'off';   
axes('Position', [0  0  1  1], 'Visible', 'off');
%
movie(mov2, 1, vid.FrameRate)