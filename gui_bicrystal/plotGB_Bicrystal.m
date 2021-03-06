% Copyright 2013 Max-Planck-Institut f�r Eisenforschung GmbH
function plotGB_Bicrystal
%% Function used to generate bicrystal interface
% authors: d.mercier@mpie.de / c.zambaldi@mpie.de

%% Set the encapsulation of data
gui = guidata(gcf);

%% Initalization
if get(gui.handles.cblegend,'Value') == 1
    set(gui.handles.pmlegend_location, 'Visible', 'on');
else
    set(gui.handles.pmlegend_location, 'Visible', 'off');
end

gui.flag.LaTeX_flag = get(gui.handles.latex, 'Value');

%% Set of plot type
% Get value of popupmenu to plot m' value (max, min...?)
valcase = get(gui.handles.pmchoicecase, 'Value');

%% Setting of popupmenu
[Phase_A, Phase_B] = plotGB_Bicrystal_get_struct;
[Material_A, Material_B] = plotGB_Bicrystal_get_material;
gui.GB.Phase_A = char(Phase_A);
gui.GB.Phase_B = char(Phase_B);
gui.GB.Material_A = char(Material_A);
gui.GB.Material_B = char(Material_B);

listSlipsA = listSlipSystems(gui.GB.Phase_A);
listSlipsB = listSlipSystems(gui.GB.Phase_B);
set(gui.handles.pmlistslipsA, 'String', listSlipsA, ...
    'max', size(listSlipsA,1));
set(gui.handles.pmlistslipsB, 'String', listSlipsB, ...
    'max', size(listSlipsB,1));
guidata(gcf, gui);

%% Setting of slip/twin systems for m' calculation
[listslipA, listslipB, no_slip] = plotGB_Bicrystal_listslips;

%% Update of Euler angles
gui.handles.pmEulerUnit_str = get_value_popupmenu(gui.handles.pmEulerUnit, ...
    get(gui.handles.pmEulerUnit, 'String'));

gui.GB.eulerA = plotGB_Bicrystal_update_euler(gui.GB.eulerA_ori, ...
    gui.handles.getEulangGrA, gui.handles.pmEulerUnit_str);
gui.GB.eulerB = plotGB_Bicrystal_update_euler(gui.GB.eulerB_ori, ...
    gui.handles.getEulangGrB, gui.handles.pmEulerUnit_str);

if strcmp(gui.handles.pmEulerUnit_str, 'Radian')
    gui.GB.eulerA = gui.GB.eulerA * 180/pi;
    gui.GB.eulerB = gui.GB.eulerB * 180/pi;
    gui.GB.eulerA_ori = gui.GB.eulerA;
    gui.GB.eulerB_ori = gui.GB.eulerB;
end
guidata(gcf, gui);

%% Update of phase number
if strcmp(gui.GB.Phase_A, gui.GB.Phase_B) == 1
    gui.GB.number_phase    = 1;
else
    gui.GB.number_phase    = 2;
end

%% Get stress tensor from map interface
gui.stressTensor = get_stress_tensor(gui.handles.stressTensor);

%% Store old view settings
if isfield(gui.handles, 'h_gbax')
    set(gcf, 'CurrentAxes', subplot(4,2,[3 6]));
    [old_az, old_el] = view;
else
    old_az = 45; % old azimuth value
    old_el = 45; % old elevation value
end

%% Initialization of bicrystal plot
gui.handles.h_gbax = subplot(4,2,[3 6], 'replace');
axis off;

%% GB Trace calculation / plot
set_default_values_txtbox (gui.handles.getGBtrace, gui.GB.GB_Trace_Angle);
gui.GB.GB_Trace_Angle = ...
    mod(str2double(get(gui.handles.getGBtrace, 'string')), 360);

% GB trace
set(gui.handles.getGBtrace, 'String', ...
    sprintf('%.1f', gui.GB.GB_Trace_Angle)); guidata(gcf, gui);
[gui.GB_geometry.gb_vec_norm, gui.GB_geometry.gb_vec, ...
    gui.GB_geometry.GB_arrow] = ...
    plotGB_Bicrystal_GB_trace(gui.GB.GB_Trace_Angle);
gui.handles.h_gbax = subplot(4,2,[3 6], 'replace');

try
    arrow(gui.GB_geometry.GB_arrow(:,1), gui.GB_geometry.GB_arrow(:,2), ...
        0, 'Length', 100, 'FaceColor', 'k', 'TipAngle', 15);
catch err
    warning_commwin(err.message);
end

% Surface plane
gui.GB_geometry.perp_gb = cross([0;0;1], gui.GB_geometry.gb_vec_norm);
gui.GB_geometry.surf_plane(:,1) = ...
    -gui.GB_geometry.gb_vec_norm - 3*gui.GB_geometry.perp_gb;
gui.GB_geometry.surf_plane(:,2) = ...
    -gui.GB_geometry.gb_vec_norm + 3*gui.GB_geometry.perp_gb;
gui.GB_geometry.surf_plane(:,3) = ...
    gui.GB_geometry.gb_vec_norm - 3*gui.GB_geometry.perp_gb;
gui.GB_geometry.surf_plane(:,4) = ...
    gui.GB_geometry.gb_vec_norm + 3*gui.GB_geometry.perp_gb;
gui.handles.h_GBsurf = patch('Vertices', gui.GB_geometry.surf_plane', ...
    'Faces', [1 3 4 2], 'FaceColor', 'b', 'FaceAlpha', 0.02);

%% GB Inclination calculation / plot GB inclined plane
set_default_values_txtbox(gui.handles.getGBinclination, ...
    gui.GB.GB_Inclination);
gui.GB.GB_Inclination = mod(str2double(get(gui.handles.getGBinclination, ...
    'String')), 180);
set(gui.handles.getGBinclination, ...
    'String', sprintf('%.1f', gui.GB.GB_Inclination));
gui.GB_geometry.GB_inclined = ...
    plot_inclined_GB_plane([0;0;0], [0;0;0], ...
    gui.GB.GB_Trace_Angle, gui.GB.GB_Inclination);
% Get the direction of the GB (for LRB parameter)
gui.GB_geometry.d_gb = gui.GB_geometry.GB_inclined(:,3) ...
    - gui.GB_geometry.GB_inclined(:,1);
gui.GB_geometry.d_gb = gui.GB_geometry.d_gb./norm(gui.GB_geometry.d_gb);
patch('Vertices', gui.GB_geometry.GB_inclined', ...
    'Faces', [1 3 4 2], 'FaceColor', 'k', 'FaceAlpha', 0.4);

%% Encapsulation of data
guidata(gcf, gui);

%% m' and RBV calculations
if ~no_slip
    plotGB_Bicrystal_mprime_calculator_all(listslipA, listslipB);
    gui = guidata(gcf); guidata(gcf, gui);
end

if ~gui.flag.error
    %% Misorientation calculation
    if strcmp(gui.GB.Phase_A, gui.GB.Phase_B) == 1
        if gui.flag.installation_mtex == 1
            gui.GB.orientation_grA = ...
                mtex_setOrientation(gui.GB.Phase_A, ...
                gui.GB.ca_ratio_A(1), gui.GB.eulerA); guidata(gcf, gui);
            
            gui.GB.orientation_grB = ...
                mtex_setOrientation(gui.GB.Phase_B, ...
                gui.GB.ca_ratio_B(1), gui.GB.eulerB); guidata(gcf, gui);
            
            gui.GB.misorientation  = ...
                mtex_getBX_misorientation(gui.GB.orientation_grB, ...
                gui.GB.orientation_grA); guidata(gcf, gui);
            
        elseif gui.flag.installation_mtex == 0
            gui.GB.misorientation  = ...
                misorientation(gui.GB.eulerA, gui.GB.eulerB, ...
                gui.GB.Phase_A, gui.GB.Phase_B); guidata(gcf, gui);
        end
    else
        gui.GB.misorientation = NaN;
    end
    
    %% Misorientation calculation
    if strcmp(gui.GB.Phase_A, 'hcp') == 1 ...
            && strcmp(gui.GB.Phase_B, 'hcp') == 1
        gui.GB.caxis_misor = eul2Caxismisor(gui.GB.eulerA, gui.GB.eulerB);
    else
        gui.GB.caxis_misor = NaN;
    end
    guidata(gcf, gui);
    
    %% Update slips from popupmenu and definition of slips A and B
    [slipA, slipB] = plotGB_Bicrystal_update_slip(no_slip);
    gui.GB.slipA = slipA;
    gui.GB.slipB = slipB;
    
    %% m' and RBV calculations for specific slips given by user for grains A and B
    if valcase == size(get(gui.handles.pmchoicecase, 'String'), 1)
        gui.GB.mprime_specific = ...
            gui.calculations.mprime_val_bc(slipA, slipB);
        
        gui.GB.rbv_specific = ...
            gui.calculations.residual_Burgers_vector_val_bc(slipA, slipB);
        
        gui.GB.nfact_specific = ...
            gui.calculations.n_fact_val_bc(slipA, slipB);
        
        gui.GB.LRBfact_specific = ...
            gui.calculations.LRB_val_bc(slipA, slipB);
        
        gui.GB.lambdafact_specific = ...
            gui.calculations.lambda_val_bc(slipA, slipB);
    end
    guidata(gcf, gui);
    
    %% Plot unit cells and circles
    [shiftXYZA, shiftXYZB] = ...
        plotGB_Bicrystal_plot_lattices(slipA, slipB, no_slip);
    
    %% Plot slip traces
    if get(gui.handles.cbsliptraces, 'Value') == 1
        shiftXYZ_A = (1.5 * gui.GB_geometry.perp_gb) + [0;0;0];
        shiftXYZ_B = -((1.5 * gui.GB_geometry.perp_gb) + [0;0;0]);
        plot_slip_traces(slipA, gui.GB.eulerA, gui.GB.Phase_A, ...
            gui.GB.ca_ratio_A(1), shiftXYZ_A, 2, 0.5);
        plot_slip_traces(slipB, gui.GB.eulerB, gui.GB.Phase_B, ...
            gui.GB.ca_ratio_B(1), shiftXYZ_B, 2, 0.5);
    end
    
    %% Plot options
    plotGB_Bicrystal_gbax_title_and_text(no_slip, shiftXYZA, shiftXYZB);
    triad_lines;
    axis off;
    axis tight;
    rotate3d on;
    view(old_az, old_el);
    
    %% Plotting of slip transmission parameter map
    if ~no_slip
        subplot(4, 2, [7 8], 'Position', [0.25, 0, 0.65, 0.2]);
        axis fill;
        
        switch(valcase)
            case {1, 2, 3, 7, 37}
                param2plot =  gui.calculations.mprime_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,2);
                titleLaTeX = 'Maximum $m''$ values';
                titleNoLaTeX = 'Maximum m'' values';
            case {4, 5, 6}
                param2plot =  gui.calculations.mprime_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,1);
                titleLaTeX = 'Minimum $m''$ values';
                titleNoLaTeX = 'Minimum m'' values';
            case {8, 9, 10, 14}
                param2plot = ...
                    gui.calculations.residual_Burgers_vector_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,2);
                titleLaTeX = ...
                    'Maximum residual Burgers vector values';
                titleNoLaTeX = ...
                    'Maximum residual Burgers vector values';
            case {11, 12, 13}
                param2plot = ...
                    gui.calculations.residual_Burgers_vector_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,1);
                titleLaTeX = ...
                    'Minimum residual Burgers vector values';
                titleNoLaTeX = ...
                    'Minimum residual Burgers vector values';
            case {15, 16, 17, 21}
                param2plot = gui.calculations.n_fact_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,2);
                titleLaTeX = 'Maximum $N$-factor values';
                titleNoLaTeX = 'Maximum N-factor values';
            case {18, 19, 20}
                param2plot = gui.calculations.n_fact_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,1);
                titleLaTeX = 'Minimum $N$-factor values';
                titleNoLaTeX = 'Minimum N-factor values';
            case {22, 23, 24, 28}
                param2plot = gui.calculations.LRB_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,2);
                titleLaTeX = 'Maximum $LRB$-factor values';
                titleNoLaTeX = 'Maximum LRB-factor values';
            case {25, 26, 27}
                param2plot = gui.calculations.LRB_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,1);
                titleLaTeX = 'Minimum $LRB$-factor values';
                titleNoLaTeX = 'Minimum LRB-factor values';
            case {29, 30, 31, 35}
                param2plot = gui.calculations.lambda_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,2);
                titleLaTeX = 'Maximum $\lambda$ values';
                titleNoLaTeX = 'Maximum lambda values';
            case {32, 33, 34}
                param2plot = gui.calculations.lambda_val_bc_all;
                plotGB_Bicrystal_min_max_param_map_plot(param2plot,1);
                titleLaTeX = 'Minimum $\lambda$ values';
                titleNoLaTeX = 'Minimum lambda values';
            case {36}
                param2plot = gui.calculations.GB_Schmid_Factor_max;
                titleLaTeX = 'No parameter to plot';
                titleNoLaTeX = 'No parameter to plot';
                subplot(4,2,7, 'replace');
                axis off;
                subplot(4,2,8, 'replace');
                axis off;
        end
        if gui.flag.LaTeX_flag
            handle_title = title(titleLaTeX, 'interpreter', 'latex');
        else
            handle_title = title(titleNoLaTeX, 'interpreter', 'none');
        end
        set(handle_title, 'color', [0 0 0], 'BackgroundColor', [1 1 1], ...
            'Position', [3.5,-2.75,0]);
    else
        subplot(4,2,7, 'replace');
        axis off;
        subplot(4,2,8, 'replace');
        axis off;
    end
    gui.GB.param2plot = param2plot;
    gui.GB.param2plot_title = titleNoLaTeX; % For all parameter values matrix
    guidata(gcf, gui);
    
end

end