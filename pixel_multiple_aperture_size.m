function L = pixel_multiple_aperture_size(aperture, ndims)
    
    % isotropic pixel size (integer) along x and y
    px = ceil(aperture/ndims);
    
    % Define dst rect as integer multiples of the frame size.
    L = px * ndims;

end


