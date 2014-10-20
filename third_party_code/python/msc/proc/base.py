# -*- coding: utf-8 -*-
"""
@author: c.zambaldi
"""
import os, sys
import math

try:
    import numpy as np
except:
    np = None

import time

from sketch import Sketch
#from msc.tools import MSC_TOOLS
from tools import Tools

#class Proc(Sketch, MSC_TOOLS):
class Proc(Sketch, Tools):
    """ This class defines the common bits needed for writing
        MSC.Marc/Mentat procedure files.
        Previously all preprocessing was done from one "class".
        Now (March 2013) it is more modular and a little bit tidier,
        thus more presentable.
    """
    proc = []  # emty list to hold the procedure file content
    import getpass

    author = 'python_package (C. Zambaldi) used by ' + getpass.getuser()
    title = 'model'
    affiliation = 'MPI fuer Eisenforschung, www.mpie.de'
    initConds = []
    CODE = 'GENMAT'
    #CODE = 'DAMASK'
    FEMSOFTWAREVERSION = 2010  # default
    FEMSOFTWARE = 'Mentat'

    header_line_mark = '|+++++++++++++++++++++++++++++++++++++++++++++\n'

    def __init__(self):
        pass

    def get_proc(self):
        return self.proc

    def header(self, label):
        """Visually separate the sections in the Mentat procedure file
        """
        assert(label is not None)
        return '\n' + self.header_line_mark + \
               '| %s\n' % label + \
               self.header_line_mark

    def start(self,
              title=None,
              author=None,
              affiliation=None):
        if title is None: title = self.title
        if author is None: author = self.author
        if affiliation is None: affiliation = self.affiliation
        self.proc.append('''
|+++++++++++++++++++++++++++++++++++++++++++++
|  PROCEDURE FILE 
|  FOR USE WITH MSC.%s''' % self.FEMSOFTWARE + ''' 
|=============================================
|        TITLE: %s\n''' % (title) + '''
|=============================================
|         AUTHOR: %s''' % author + ''', %s''' % affiliation + '''
|           DATE: %s''' % (str(time.ctime())) + '''
| GENERATED WITH: msc package by C. Zambaldi
|                  MPI fuer Eisenforschung
|+++++++++++++++++++++++++++++++++++++++++++++
| USAGE IN MENTAT: 
|   /!\ Save current model /!\, then
|   UTILS > PROCEDURES > LOAD > START/CONT
|+++++++++++++++++++++++++++++++++++++++++++++
''')

    def procNewModel(self):
        self.proc.append('''
|+++++++++++++++++++++++++++++++++++++++++++++
| NEW MODEL
*new_model yes\n*select_reset\n*plot_reset\n*expand_reset\n*move_reset
|+++++++++++++++++++++++++++++++++++++++++++++
*set_sweep_tolerance
0.0001 | the MSC.Marc default value
''')


    def procIndentDocCall(self):
        self.proc.append('''
|=== procIndentDocCall    
|The parameters with which preIndentation was called were:    
|m.preIndentation(
''')
        #P=self.IndentParameters
        P = self.callerDict
        callString = 'preIndentation('
        for k in iter(P):
            callString += '%s=%s, ' % (k, str(P[k]))
        self.proc.append('| %s)' % callString)


    def procParameters(self):
        self.header('PARAMETER-DEFINITION')


    def procParametersUniax(self, smv=0.01,
                            eps_max=0.25, def_time=100.,
                            nr_incr=100):
    #az=12 für tessel666d2
        self.proc.append('''
| generated by procParameterUniax
|+++++++++++++++++++++++++++++++++++++++++++++
|++ GEOMETRY ++++++
*define smv %f        | small_value wegen node_sets''' % (smv) + '''
*define ax %f         | Element''' % self.modelDim[0] + '''
*define ay %f''' % self.modelDim[1] + '''
*define az %f''' % self.modelDim[2] + '''
*define divix %i''' % self.divi[0] + '''
*define diviy %i''' % self.divi[1] + '''
*define diviz %i''' % self.divi[2] + '''
\n|++ DEFORMATION +++\n
*define eps_max %f     | Maximal engineering strain''' % (eps_max) + '''
*define eps_dot 0.001  | Strain rate (for engineering strain)
*define def_time %f    | old:eps_max/eps_dot    | time for loadcase''' % (def_time) + '''
*define nr_incr %i     | Number of increments''' % (nr_incr) + '''
*renumber_all\n*sweep_all\n
''')


    def procSample(self):
        self.header('SAMPLE-MODELING AND MESHING')


    def proc_points(self, p_list):
        p_str = '*add_points\n'
        for n, p in enumerate(p_list):
            p_str += '%e %e %e | %i \n' % (p[0], p[1], p[2], n)
        return p_str

    def proc_nodes(self, n_list):
        n_str = '*add_nodes\n'
        for i, n in enumerate(n_list):
            n_str += '%e %e %e | %i \n' % (n[0], n[1], n[2], i)
        return n_str


    def procNodeSets(self):
        self.proc.append('''
|++++++++++++++++++++
| NODE SET DEFINITION
*select_clear
*select_filter_surface
*select_nodes
all_existing
*select_reset
*store_nodes prescribed_nodes
all_selected
*store_nodes surf_nodes
all_selected
*select_clear


| Nodes on Cube faces
|## faces xmin
*select_reset
*select_method_box
*select_nodes
-smv smv
-smv ay+smv
-smv az+smv
*store_nodes xminf_nds
all_selected
*select_clear

|## faces xmax
*select_nodes
ax-smv ax+smv
-smv ay+smv
-smv az+smv
*store_nodes xmaxf_nds
all_selected
*select_clear

|## faces ymin
*select_nodes
-smv ax+smv
-smv +smv
-smv az+smv
*store_nodes yminf_nds
all_selected
*select_clear

|## faces ymax
*select_nodes
-smv ax+smv
ay-smv ay+smv
-smv az+smv
*store_nodes ymaxf_nds
all_selected
*select_clear

|## faces zmin
*select_nodes
-smv ax+smv
-smv ay+smv
-smv smv
*store_nodes zminf_nds
all_selected
*select_clear

|## faces zmax
*select_nodes
-smv ax+smv
-smv ay+smv
az-smv az+smv
*store_nodes zmaxf_nds
all_selected
*select_clear

| Nodes on cube faces, but not intersecting on the boundaries (for periodic boundary conditions)
|## periodic xmin
*select_reset
*select_method_box
*select_nodes
-smv smv
-smv ay+smv
-smv az+smv
*store_nodes xmin_nds
all_selected
*select_clear

|## periodic xmax
*select_nodes
ax-smv ax+smv
-smv ay+smv
-smv az+smv |z
|-smv az-smv |z D.
*store_nodes xmax_nds
all_selected
*select_clear

|## periodic ymin
*select_nodes
|-smv ax+smv  |x
-smv ax-smv  |x D.
-smv smv
-smv az+smv
*store_nodes ymin_nds
all_selected
*select_clear

|## periodic ymax
*select_nodes
|-smv ax+smv
-smv ax-smv | L.Delannay
ay-smv ay+smv
-smv az+smv
*store_nodes ymax_nds
all_selected
*select_clear

|## periodic zmin
*select_nodes
|-smv ax+smv |x
-smv ax-smv |x D.
|-smv ay+smv |y
-smv ay-smv |y D.
-smv smv
*store_nodes zmin_nds
all_selected
*select_clear

|## periodic zmax
*select_nodes
|-smv ax+smv |x
-smv ax-smv |x D.
|-smv ay+smv |y
-smv ay-smv |y D.
az-smv az+smv
*store_nodes zmax_nds
all_selected
*select_clear


| EVALUATION NODES SET
*set_node_labels on
*select_clear
*select_method_box
*select_nodes
-smv smv
-smv smv
0.2*h 0.8*h
*store_nodes evaluate_nodes
all_selected

*select_clear
*select_method_box
*select_elements
-d smv
-d smv
-smv h+smv
*store_elements quarter_elements
*all_selected
*invisible_selected
''')


    def procBoundaryConditions(self):
        self.header('BOUNDARY CONDITIONS')

    def procNodeFixXYZ(self, name='node1_fix_all',
                       nodes=[1]):
        nodestr = ''
        for i in range(0, len(nodes)):
            nodestr = nodestr + ' %i' % nodes[i]
        self.proc.append('''
*new_apply
*apply_name\n%s''' % name + '''
*apply_dof x *apply_dof_value x
0
*apply_dof y *apply_dof_value y
0
*apply_dof z *apply_dof_value z
0
*add_apply_nodes\n%s''' % nodestr + '''
#
''')

    def procLoadCase(self):
        self.header('LOADCASES DEFINITION')


    def procTable(self, tablename='displacement',
                  tabletype='time',
                  tablepoints=[(0., 0.), ('def_time', 'eps_max*az')]):
        self.proc.append('''
|
| TABLE DEFINITION
|
*new_table
*table_name
%s''' % tablename + '''
*set_table_type
%s''' % tabletype + '''
*table_add''')
        for pts in tablepoints:
            self.proc.append('%s\n%s' % (pts[0], pts[1]))
        self.proc.append('''\n*show_table\n*table_fit\n*table_filled\n''')


    def procContact(self):
        self.header('CONTACT DEFINITION')

    def deg2rad(self, deg):
        return (deg / 180. * math.pi)

    def rad2deg(self, rad):
        return (rad * 180. / math.pi)

    def e1(self):
        return np.array([1., 0., 0.])

    def e2(self):
        return np.array([0., 1., 0.])

    def e3(self):
        return np.array([0., 0., 1.])


    def procInitCond(self, iconds=['icond_mpie'], ic_els=['all_existing']):
        self.proc.append(self.header('INITIAL CONDITIONS'))
        self.initConds.extend(iconds)
        for ic in range(0, len(iconds)):
            self.proc.append('''
*new_icond      
*icond_name
%s
*icond_type state_variable
*icond_param_value state_var_id
2
*icond_dof var *icond_dof_value var
%i
*add_icond_elements
%s\n''' % (iconds[ic], ic + 1, ic_els[ic]))

    def procInitCondSV(self, label=['icond_mpie'],
                       StateVariableNumber=None,
                       StateVariableValue=None,
                       elements='all_existing',
                       new=True):
        self.initConds.append(label)
        icond = self.init_cond_state_var(label=label,
                                         StateVariableNumber=StateVariableNumber,
                                         StateVariableValue=StateVariableValue,
                                         elements=elements,
                                         new=new)
        self.proc.append(icond)

    def init_cond_state_var(self,
                            label=['icond_mpie'],
                            StateVariableNumber=None,
                            StateVariableValue=None,
                            elements='all_existing',
                            new=True):
        icond = ''
        if new:
            icond += '*new_icond\n'
        icond += '''
*icond_name
%s
*icond_type state_variable
*icond_param_value state_var_id
%i
*icond_dof var *icond_dof_value var
%i
*add_icond_elements
%s\n''' % (label, StateVariableNumber, StateVariableValue, elements)
        return icond


    def procInitCondDamask(self, T=300, # temperature (K)
                           H=[1], # homogenization
                           M=[1]  # microstructure
    ):
        self.procInitCondSV(label='icond_temperature',
                            StateVariableNumber=1,
                            StateVariableValue=T)
        for h in H:
            self.procInitCondSV(label='icond_homogenization_%i' % h,
                                StateVariableNumber=2,
                                StateVariableValue=h)
        for m in M:
            self.procInitCondSV(label='icond_microstructure_%i' % m,
                                StateVariableNumber=3,
                                StateVariableValue=m)


    def procMaterial(self, name='hypela2', els='all_existing'):
        self.header('MATERIAL DATA')
        self.proc.append('''
*material_name %s''' % name + '''
*material_type mechanical:hypoelastic
*material_option hypoelastic:method:hypela2
*material_option hypoelastic:pass:def_rot
*add_material_elements
%s\n''' % (els))

    def procMaterialElast(self, name='hypela2', els='all_existing'):
        self.header('MATERIAL DATA')
        self.proc.append('''
*material_name %s''' % name + '''
*material_type mechanical:hypoelastic
*material_option hypoelastic:method:hypela2
*material_option hypoelastic:pass:def_rot
*add_material_elements
%s\n''' % (els))


    def procGeometricProperties(self, cdil='on'):
        self.header('GEOMETRIC PROPERTIES')
        self.proc.append('''
*geometry_type mech_three_solid
*geometry_option cdilatation:%s''' % cdil + '''
*geometry_option assumedstrn:off
*geometry_option ctemperature:on
*geometry_option red_integ_capacity:off
*add_geometry_elements
all_existing\n''')


    def procJobDef(self, cpfemLoc='mpie_marc_cz.f'):
        self.header('JOB DEFINITION')
        self.proc.append('''
*sweep_all\n*surfaces_wireframe *regen
*job_class mechanical
''')
        for ic in self.initConds:
            self.proc.append('''
*add_job_iconds %s
''' % ic)
        self.proc.append('''
| ANALYSIS OPTIONS
|| Large Displacement
*job_option large:on
|| Plasticity Procedure: Large strain additive
*job_option plasticity:l_strn_mn_add
|| Advanced Options
||| CONSTANT DILATATION (moved to Geometric Properties Section in Marc 2008r1)
*job_option cdilatation:on
||| Updated Lagrange Procedure
*job_option update:on
||| Large Strains
*job_option finite:on
||| Multiplicative Decomposition (large stra =2)
*job_option plas_proc:multiplicative

| JOB PARAMETERS
|| Solver: Nonsymmetrical Solution
*job_option solver_nonsym:on
| SOUBROUTINE DEFINITION
*job_usersub_file %s''' % (cpfemLoc) + '''
|*job_usersub_file only_forcdt.f

*job_option user_source:compile_save
|*job_option user_source:run_saved

''')

    def proc_copy_job(self,
                      jobname=None, # e.g. ori
                      number=None):  # e.g. nr of ori
        p = '*copy_job\n'
        if number is not None:
            jobname += '%03i' % number
        if jobname is not None:
            #jobname = 'copied_job'
            p += '*job_name %s\n' % jobname
        self.proc.append(p)

    def copy_jobs_for_oris(self):
        pass

    def write_dat(self):
        self.proc.append('*job_write_input yes\n')
        self.proc.append('*copy_job\n')
        self.proc.append('*job_name postdef\n')

    def procAnalysisOptions(self):
        self.proc.append('''| ANALYSIS OPTIONS
|| Large Displacement
*job_option large:on
|| Plasticity Procedure: Large strain additive
*job_option plasticity:l_strn_mn_add
|| Advanced Options
||| CONSTANT DILATATION
*job_option cdilatation:on
||| Updated Lagrange Procedure
*job_option update:on
||| Large Strains
*job_option finite:on
||| Multiplicative Decomposition (large stra =2)
*job_option plas_proc:multiplicative''')

    def procJobResults(self, step=5):
        self.proc.append('''|++++++++++++
| JOB RESULTS
|*job_option post ascii/binary | Write Result File as formatted ASCII or binary
*job_param post %i | write each ith increment to *.t16 (binary) or *.t19 (ascii)''' % step + '''
*add_post_tensor stress
*add_post_tensor strain
*add_post_tensor cauchy
*add_post_var temperature
*add_post_var state2  homogenization | Homogenization ID of MPIE crystal-plasticity (old material ID)
*add_post_var state3  microstructure | Microstructure ID of MPIE crystal-plasticity
*add_post_var von_mises
*add_post_var eel_strain
*add_post_var ecauchy
*add_post_var te_energy
*add_post_var tepl_strain
*add_post_var thickness
*add_post_var eq/yl_stress
*add_post_var volume         | volume (initial)
*add_post_var cur_volume     | volume (current)
''')
        if self.CODE == 'GENMAT':
            self.proc.append('''
*add_post_var user1
*edit_post_var user1 Approx. element thickness
*add_post_var user2
*edit_post_var user2 phi1
*add_post_var user3
*edit_post_var user3 PHI
*add_post_var user4
*edit_post_var user4 phi2
*add_post_var user5
*edit_post_var user5 Misorientation angle
*add_post_var user6
*edit_post_var user6 Accumulated slip
|*add_post_var user7 Vol fraction was excluded from subroutine (CZambaldi)
|*edit_post_var user7 Vol fraction
*add_post_var user7
*edit_post_var user7 gam1new
*add_post_var user8
*edit_post_var user8 gam2new
*add_post_var user9
*edit_post_var user9 gam3new
*add_post_var user10
*edit_post_var user10 gam4new
*add_post_var user11
*edit_post_var user11 gam5new
*add_post_var user12
*edit_post_var user12 gam6new
*add_post_var user13
*edit_post_var user13 gam7new
*add_post_var user14
*edit_post_var user14 gam8new
*add_post_var user15
*edit_post_var user15 gam9new
*add_post_var user16
*edit_post_var user16 gam10new
*add_post_var user17
*edit_post_var user17 gam11new
*add_post_var user18
*edit_post_var user18 gam12new
*add_post_var user19
*edit_post_var user19 gam13new
*add_post_var user20
*edit_post_var user20 gam14new
*add_post_var user21
*edit_post_var user21 gam15new
*add_post_var user22
*edit_post_var user22 gam16new
*add_post_var user23
*edit_post_var user23 gam1dot
*add_post_var user24
*edit_post_var user24 gam2dot
*add_post_var user25
*add_post_var user26
*add_post_var user27
*add_post_var user28
*add_post_var user29
*add_post_var user30''')


    def procJobParameters(self):
        self.proc.append('''| JOB PARAMETERS
|| Solver: Nonsymmetrical Solution
*job_option solver_nonsym:on
| SOUBROUTINE DEFINITION
*job_usersub_file %s'''%({'GENMAT':'mpie_marc_cz.f','DAMASK':'DAMASK_marc.f90'}[self.CODE]) + '''
|*job_usersub_file only_forcdt.f
*job_option user_source:compile_save
|*job_option user_source:run_saved''')

    def proc_usersub_def(self):
        #TODO: gibts in procJobParameters und in ProcJobDef
        pass

    def procFriction(self):
        self.proc.append('''|+++++++++++++++++++++++++++++++++++
| FRICTION            \n
|job_option frictype:<none/coul_stick_slip/shear/ coulomb/shear_roll/coulomb_roll>
|*job_option frictype''')


    def procCleanUp(self, sweepTol=0.001):
        self.proc.append('''
|++++ CLEAN UP +++++++    
*sweep_all
*remove_unused_nodes
*renumber_all
''')

    def procSaveModel(self, modelname='model.mfd'):
        self.proc.append('''
|+++++++++++++++++++++++
| SAVE MODEL
*sweep_all
*renumber_all
*save_as_model %s yes
*update_job
|*submit_job 1
|*submit_job 2  | nur bei compile_save
|*pause 4
*monitor_job
|@top()
|@push(jobs)
|@popup(job_run_popmenu)\n''' % modelname)


    def norm(self, vec):
        if len(vec) == 3:
            n = math.sqrt(vec[0] ** 2. + vec[1] ** 2. + vec[2] ** 2.)
        else:
            raise (ValueError)
        return n

    #  def procSetMoveTranslations(self,f,t):
    #



    def getNodeSets(self):
        '''Not used by now'''
        #self.setPostname=self.post_dummy
        #print postname
        # Read element sets
        print 'getNodeSets: Trying to open dummy', os.getcwd(), '/', postname, ' ...'
        self.p = opent16(self.post_dummy)
        if self.p == None:
            self.p = post_open(postname[0:-1] + '9') # is it *.t19 file?
            if self.p == None:
                print 'Could not open %s. run make_post' % postname;
                sys.exit(1)
        self.p.moveto(0)
        nnds = self.p.nodes();
        print  nnds

        nSets = self.p.sets()
        print nSets
        self.nodeSets = {}
        for i in range(0, nSets - 1):
            s = self.p.set(i)
            print 'Set: ', s.name, ', Type: ', s.type, '\n', s.items
            exec ('self.nodeSets[''%s'']=s.items' % s.name)
            #print 'xmin: ',xmin_nds,'\nxmax: ',xmax_nds


    def ParticleLinks(self):
        self.getNodeSets()
        #f=open('servo.proc','w')# store servo definitions in proc-file
        #self.write2servo(f=f,tie,dof=1,ret,coeff=(1, 1, 1))

    def quit_mentat(self):
        self.proc.append('*quit yes\n') # exit mentat after model is built
        
    def proc_draw_update_manual(self):
        self.proc.append('*draw_manual\n')
    def proc_draw_update_automatic(self):
        self.proc.append('*draw_automatic\n')
        
    def to_file(self, dst_path=None, dst_name=None):
        '''Write  self.proc list to file'''
        if dst_name is None:
            dst_name = 'msc_procedure_file.proc'
            #try:
        #    self.procfilename
        #except:
        #    self.procfilename=dst_name
        self.procfilename = dst_name
        if dst_path is not None:
            self.procpath = dst_path
        else:
            self.procpath = './'
        filename = os.path.join(self.procpath, self.procfilename)
        print(filename)
        self.print_commands(self.proc, filename=filename)