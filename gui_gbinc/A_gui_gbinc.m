% Copyright 2013 Max-Planck-Institut f�r Eisenforschung GmbH
function A_gui_gbinc
%% This toolbox helps to find the grain boundary inclination from two micrographs
% with the same scale obtained before and after a serial polishing.
% At least three marks such as microindents are needed for registration of the images.

% authors: d.mercier@mpie.de / c.zambaldi@mpie.de

%% Toolbox configuration
gui.config.gbinc_root_fullpath = mfilename('fullpath');
[gui.config.gbinc_root, gui.config.gbinc_root_filename,...
    gui.config.gbinc_ext] = fileparts(gui.config.gbinc_root_fullpath);

warning off; %to avoid warnings with uibuttongroups...

gui.config.toolboxversion = '1.0';
gui.config.toolboxname = strcat('Toolbox_for_GB_Inclination_Calculation_',...
    gui.config.toolboxversion);

gui.config.defaults.picture_before.fullpath = fullfile(gui.config.gbinc_root,...
    'sem_pictures_serial_polishing', 'cpTi_before_polishing.tif');
[gui.config.defaults.picture_before.pathname, ...
    gui.config.defaults.picture_before.filename, ...
    gui.config.defaults.picture_before.extension] = ...
    fileparts(gui.config.defaults.picture_before.fullpath);

gui.config_map.pathname_image_before_polishing = gui.config.defaults.picture_before.pathname;
gui.config_map.filename_image_before_polishing = strcat(gui.config.defaults.picture_before.filename, ...
    gui.config.defaults.picture_before.extension);
gui.config_map.fullpath_image_before_polishing = fullfile(...
    gui.config_map.pathname_image_before_polishing, gui.config_map.filename_image_before_polishing);

gui.config.defaults.picture_after.fullpath = fullfile(gui.config.gbinc_root,...
    'sem_pictures_serial_polishing', 'cpTi_post_polishing.tif');
[gui.config.defaults.picture_after.pathname, ...
    gui.config.defaults.picture_after.filename, ...
    gui.config.defaults.picture_after.extension] = ...
    fileparts(gui.config.defaults.picture_after.fullpath);

gui.config_map.pathname_image_after_polishing = gui.config.defaults.picture_after.pathname;
gui.config_map.filename_image_after_polishing = strcat(gui.config.defaults.picture_after.filename, ...
    gui.config.defaults.picture_after.extension);
gui.config_map.fullpath_image_after_polishing = fullfile(...
    gui.config_map.pathname_image_after_polishing, gui.config_map.filename_image_after_polishing);

%% Initialization of flags
gui.flag.image1          = 1;
gui.flag.image2          = 1;
gui.flag.calibration_1   = 0;
gui.flag.calibration_2   = 0;
gui.flag.edgedetection_1 = 0;
gui.flag.edgedetection_2 = 0;
gui.flag.overlay         = 0;
gui.flag.vickersdist     = 0;
gui.flag.gbdist          = 0;

%% Main Window Coordinates Configuration
scrsize = get(0, 'ScreenSize');   % Get screen size
WX = 0.05 * scrsize(3);           % X Position (bottom)
WY = 0.10 * scrsize(4);           % Y Position (left)
WW = 0.90 * scrsize(3);           % Width
WH = 0.80 * scrsize(4);           % Height

x0 = 0.01;
hu = 0.1; % height unit
wu = 0.1; % width unit

%% Main window setting
gui.handles.main_window = figure('Name', gui.config.toolboxname,...
    'NumberTitle', 'off',...
    'PaperUnits', get(0, 'defaultfigurePaperUnits'),...
    'Color', [0.9 0.9 0.9],...
    'Colormap', get(0,'defaultfigureColormap'),...
    'toolBar', 'figure',...
    'InvertHardcopy', get(0, 'defaultfigureInvertHardcopy'),...
    'PaperPosition', [0 7 50 15],...
    'Position', [WX WY WW WH]);

parent = gui.handles.main_window;

%% Buttons to import/analyze picture before serial polishing
gui.handles.image_before_polishing = gui_gbinc_buttons_load_set_image(x0, ...
    hu, wu, 1, gui.config.defaults.picture_before.filename);

%% Buttons to import/analyze picture after serial polishing
gui.handles.image_after_polishing = gui_gbinc_buttons_load_set_image(x0, ...
    hu/1.5, wu, 2, gui.config.defaults.picture_after.filename);

%% Overlay buttons
gui.handles.overlay = gui_gbinc_buttons_overlay(x0, hu, wu);

%% Vickers indents analysis
gui.handles.vickers_indents = gui_gbinc_buttons_vickers_indents(x0, hu, wu);

%% GB inclination calculations
gui.handles.gb_inclination = gui_gbinc_buttons_gb_inclination(x0, hu, wu);

%% Buttons to switch pictures plot
gui.handles.switch_plot = uibuttongroup('visible','on',...
    'Position',[x0*33 hu*9.4 wu*2.5 x0*5]);

pb1 = uicontrol('Parent', gui.handles.switch_plot ,...
    'Units','normalized',...
    'Style', 'pushbutton',...
    'Position', [x0*5 hu wu*4 x0*80],...
    'String', 'Image before polishing',...
    'BackgroundColor', [0.2 0.8 0],......
    'Callback','gui_gbinc_switch_plot(1)');

pb2 = uicontrol('Parent', gui.handles.switch_plot,...
    'Units','normalized',...
    'Style', 'pushbutton',...
    'Position', [x0*55 hu wu*4 x0*80],...
    'String', 'Image after polishing',...
    'Callback','gui_gbinc_switch_plot(2)');

gui.handles.switch_plot.pb1 = pb1;
gui.handles.switch_plot.pb2 = pb2;

%% Others buttons
gui.handles.documentation = uicontrol('Parent', parent,...
    'Units', 'normalized',...
    'Style', 'pushbutton',...
    'Position', [x0 hu*1.6 wu x0*5],...
    'String', 'DOCUMENTATION',...
    'Callback', 'web(''https://github.com/stabix/gbinc/blob/master/README.txt'',''-browser'')');

gui.handles.reset = uicontrol('Parent', parent,...
    'Units','normalized',...
    'Style', 'pushbutton',...
    'Position', [x0 hu wu x0*5],...
    'String', 'RESET',...
    'Callback', 'close_windows(gcf); A_gui_gbinc');

%% Axis settings
gui.handles.main_axis = axes('Parent', parent,...
    'Position', [x0*33 hu/20 wu*6.5 x0*92]);
axis off;

%% Load first image en gui encapsulation
guidata(parent, gui);
gui_gbinc_load_image(gui.config.defaults.picture_before.pathname, ...
    strcat(gui.config.defaults.picture_before.filename,...
    gui.config.defaults.picture_before.extension));
gui = guidata(gcf);guidata(parent, gui);

warning on;

end