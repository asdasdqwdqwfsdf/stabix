% Copyright 2013 Max-Planck-Institut f�r Eisenforschung GmbH
function list = slip_systems_names(lattice_type, varargin)
%% Function used to set slip systems lists for popup menus in the GUI
% lattice_type = hcp, bcc or fcc
% author: d.mercier@mpie.de

if nargin == 0
    lattice_type = 'hcp';
end

listSlips_hex = {'All Slips and Twins';'All Slips';'Basal';'Prism1<a>';'Prism2<a>';'Pyram1<a>';'Pyram1<c+a>';'Pyram2<c+a>';'All Twins';'No slips & No Twins'};
listSlips_bcc = {'All Slips and Twins';'All Slips';'Slips {110}';'Slips {211}';'Slips {321}';'All Twins';'No slips & No Twins'};
listSlips_fcc = {'All Slips and Twins';'All Slips';'All Twins';'No slips & No Twins'};

%% Setting of slips and twins systems
if strcmp(lattice_type,'hcp') == 1
    list = listSlips_hex;
    
elseif strcmp(lattice_type,'fcc') == 1
    list = listSlips_fcc;
    
elseif strcmp(lattice_type,'bcc') == 1
    list = listSlips_bcc;
    
end

end