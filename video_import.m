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

%% mp4 File list in Movie folder
moviedir = '/Users/peterfish/Movies/';
movext   = '*.mp4';
% movie from files
files = dir(fullfile(moviedir, movext));
nummovies = length(files);
if nummovies < 1
  error('no movies in designated folder');
else 
    for fileidx = 1:nummovies
        disp([num2str(fileidx), ': ', files(fileidx).name]); 
    end
end
%movies = cell(nummovies, 1);

%% Open Movie file
%moviedir = '/Users/peterfish/Movies/';
%vid = VideoReader([mpath,'Bee_Honet.mp4']);
id = 2;
%
vid = VideoReader([moviedir, files(id).name])
vidHeight = vid.Height;
vidWidth = vid.Width;
tot_numFrame = ceil(vid.Duration * vid.FrameRate)
f_name = split(vid.Name, '.');
str_mat = sprintf('mov_%s_f%d.mat', f_name(1), tot_numFrame)
str_mat_int = sprintf('mov_%s_f%d_intensity.mat', f_name(1), tot_numFrame)

% NOTE: why struct for each frame? Very convinient to append frames. No need
% to carefully match dimensions. 
mov = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),...
'colormap',[]);

% Define the 1st struct object. Then, the field (e.g. 'colormap') will continue even for
% appended object.

%% Construct mov struct
numFrame = 10000;
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

%% Resize & Gray conversion (Mean over color ch) & Save
numFrame = numel(mov);
scaling = 0.5; % 640 x 360
 mm_intensity = zeros(numFrame, vidHeight*scaling, vidWidth*scaling, 'uint8');
mov2_intensity = struct('cdata',zeros(vidHeight*scaling, vidWidth*scaling, 'uint8'), 'colormap', gray(255));

for k=1:numFrame
    % Convert to 16-bit integer in case that the sum can be over 255.
    %cdata = uint16(mov2(k).cdata);
    
    % resize by 0.5
    cdata = imresize(mov(k).cdata, scaling, 'bilinear');
    
    % intensity
      mm_intensity(k, :, :) = uint8(mean(cdata, 3)); % output of mean is double.
    mov2_intensity(k).cdata = uint8(mean(cdata, 3));
end
%%
save([moviedir,str_mat_int], 'mm_intensity');

%% Play the movie (movie(M,n,fps))
%[rows, cols, ~] = size(mov2(1).cdata)
hfig = figure('Position', [950, 550, 640, 360]);       
    hfig.Color = 'none';
    hfig.PaperPositionMode = 'auto';
    hfig.InvertHardcopy = 'off';   
axes('Position', [0  0  1  1], 'Visible', 'off');
movie(mov2_intensity, 1, vid.FrameRate)


%%
% Color adjust for Mouse cones.
% My projector: R-UV-B
numFrame = numel(mov);
scaling = 0.5; % 640 x 360
% matrix (color & gray)
mm = zeros(numFrame, vidHeight*scaling, vidWidth*scaling, 3, 'uint8');
% video structure
mov2 = struct('cdata',zeros(vidHeight*scaling, vidWidth*scaling, 3,'uint8'), 'colormap',[]);

for k=1:numFrame
    % Convert to 16-bit integer in case that the sum can be over 255.
    %cdata = uint16(mov2(k).cdata);
    
    % resize by 0.5
    cdata = imresize(mov(k).cdata, scaling, 'bilinear');
    cdata = uint16(cdata);
    
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
%
%save([moviedir,str_mat], 'mm');

