function grating = grating_generator_1row(w_grating, size)
% single-row grating pattern generator
% Num of gratings is floored. 

n_grating = floor(size/w_grating);
m = mod(meshgrid(1:n_grating,1),2);

grating = expandTile(m, 1, w_grating);

end