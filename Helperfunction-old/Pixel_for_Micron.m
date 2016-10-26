function px = Pixel_for_Micron(x)
    px = round(x * PIXELS_PER_100_MICRONS/100.);
end