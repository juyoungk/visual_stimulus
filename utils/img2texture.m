function tex = img2texture(ex, img, patch_size, tex_size, contrast, rs)       
%
% Take a subpart of the image, then resize, make a texture at the window object with a given
% contrast
%
% patch_size = [x y]
% tex_size = [x y]

if nargin < 6
    rs = 150 % random seed
end;

patch_size = round(patch_size);
tex_size = round(tex_size);

% image size check
if min(size(img)) < patch_size
    disp('! The chosen image has smaller pixel numbers than wanted image patch. Patch size is adjusted.');
    patch_size = size(img)
end

row = max(randi(rs, size(img,1) - patch_size), 1);    % if shift is larger than img size, col = 1
col = max(randi(rs, size(img,2) - patch_size), 1);
row_end = min(row + patch_size(2) - 1, size(img,1));
col_end = min(col + patch_size(1) - 1, size(img,2));

rowPixels = row:row_end;
colPixels = col:col_end;
patch = 2 * img(rowPixels, colPixels) * contrast + (1 - contrast);
patch_res = imresize(patch, [tex_size(2) tex_size(1)]); %[row col]
tex = Screen('MakeTexture', ex.disp.winptr, ex.disp.gray * patch_res);

end
