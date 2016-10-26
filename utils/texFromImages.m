function tex = texFromImages(ex, images, patch_size, tex_size, contrast, rs)

if nargin < 6
    rs = 150 % random seed
end;

if iscell(images)
    numimages = numel(images);
    % Pick one image and rescale (function defined in the below by Lane)
    %img = rescale(images{randi(rs, numimages)}); 
    img = images{randi(rs, numimages)};
    
elseif ismatrix(images)
    img = images;
else
    error('invalid input to texFromImages');
end

img = scaled(img);
tex = img2texture(ex, img, patch_size, tex_size, contrast, rs);    

end
