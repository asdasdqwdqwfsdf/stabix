% Copyright 2013 Max-Planck-Institut f�r Eisenforschung GmbH
function gui_gbinc_load_image(pathname, filename)
%% Function used to load images
% authors: d.mercier@mpie.de / c.zambaldi@mpie.de

gui = guidata(gcf);

%% Load images
zoom reset;
image_loaded = imread(fullfile(pathname, filename));

imshow(image_loaded);

guidata(gcf, gui);

end