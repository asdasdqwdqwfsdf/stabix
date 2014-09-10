% Copyright 2013 Max-Planck-Institut f�r Eisenforschung GmbH
function femproc_custom_menu_SX(parent)
%% Function used to add a custom menu item in the GUI menubar
% parent: handle of the GUI

% authors: d.mercier@mpie.de / c.zambaldi@mpie.de

uimenu(parent, 'Label', 'Load CPFEM material config. file', ...
    'Callback', 'femproc_load_YAML_material_file(1)',...
    'Separator','on');

uimenu(parent, 'Label', 'Edit YAML material config. file', ...
    'Callback', 'gui = guidata(gcf); edit(sprintf(''config_CPFEM_material_%s.yaml'', gui_SX.config.username))');

uimenu(parent, 'Label', 'Load Single Crystal config. file', ...
    'Callback', 'femproc_load_YAML_BX_config_file(0,1)',...
    'Separator','on');

uimenu(parent, 'Label', 'Edit YAML Single Crystal config. file', ...
    'Callback', 'gui_SX = guidata(gcf); edit(gui_SX.config_map.imported_YAML_GB_config_file)');

%uimenu(parent, 'Label', 'Load indenter topography (AFM data)', 'Callback', 'femproc_load_indenter_topo_AFM');

uimenu(parent, 'Label', 'Save mesh picture', ...
    'Callback', 'gui_SX = guidata(gcf); save_figure; set(gui_SX.handles.gui_SX_win, ''Color'', [1 1 1]*.9);', ...
    'Separator','on');

uimenu(parent, 'Label', 'Save mesh settings', ...
    'Callback', 'gui_SX = guidata(gcf); save_data(pwd, gui_SX.GB)');

uimenu(parent, 'Label', 'Show single crystal conventions', ...
    'Callback', 'gui_SX = guidata(gcf); web(gui_SX.config.path_picture_SXind)', ...
    'Separator','on');

femproc_custom_menu_edit_gui(parent, 'A_femproc_windows_indentation_setting_SX');

end