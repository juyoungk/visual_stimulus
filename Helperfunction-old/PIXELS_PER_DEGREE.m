function pix = PIXELS_PER_DEGREE(species_or_size)
% Convenience function to convert from degrees of visual field to monitor
% pixels. Actual computation is in two steps, from 1 deg of visual angle to
% actual microns in the retina (depending on species' eye size). Once the
% size in the retina equivalent to 1 deg is known then the monitor
% magnification has to be adjusted
pix = MICRONS_PER_DEGREE(species_or_size) * PIXELS_PER_100_MICRONS/100;