# NEI_analyzeLocalizers

Code related to the processing of retinotopy and localizers floc and mloc in NEI dataset

Before running scripts inside `NEI_analysis/` must change paths inside
setup.sh (see below) for correct paths to dependencies and modules. Path is set to
`/scratch/projects/corevisiongrantnei` if the `$CLUSTER` environmental
variable is equal to `GREENE` (and thus we think we're on NYU's greene cluster);
ideally this would be a general solution for different compute clusters, but we
couldn't come up with one.

Main scripts:
- `masterScript.sh`: checks for dependencies (matlab, freesurfer license, python
environment) and calls the rest of the scripts to run prfvista on retinotopy data and GLMsingle on the localizer data (floc and mloc). 
To run this script on all subjects' data for both retinotopy and localizers, run sh masterScriptGLM.sh -subjects all -sessions all
To run this script on one or more subjects/sessions passed into the function, run sh masterScriptGLM.sh -subjects <subject1name> <subject2name> -sessions <sesname1> <sesname2>
Example subjectname is wlsubj120, and example sesname is nyu3t01 (for prf) and nyu3t02 (for localizers)
- `run_glm_single.sh`: called by masterScriptGLM.sh and submits job to run
  GLM on the preprocessed data (just the `floc` and `mloc` tasks), estimating the response of each voxel per trial. Uses MATLAB.
- `run_prf.sh`: called by masterScriptGLM.sh and submits job to run retinotopy analysis
- `run_atlasmgz.sh`: called by masterScriptGLM.sh and submits job to convert wang and glasser atlases to native surface space
- `setup.sh`: called at the beginning of each script to set environmental
  variables to make sure we get paths correct.

Sub-scripts:
- `subroutines/`, contains helper scripts used by the main scripts:
  - `run_glm_single.m`: called by run_glm_single.sh, actually calls GLMsingle on the data, after setting the
    various arguments. Saves out many images for examining the quality of the
    fit. Uses MATLAB, python, and the Winawer Lab `MRI_tools` repo (see below).
    Details: Converts files to mgz, and runs bidsGLM(), which internally runs [GLMsingle](https://github.com/cvnlab/GLMsingle), then calls GLMdenoisePNGprocess.py to generate pngs
    of GLMdenoise output, and writeContrastMaps() to generate images of beta contrats defined in localizers_params.json
  - `writeContrastMaps.m`: called by run_glm_single.sh, generates mgz for each beta and contrasts of interest as defined in localizers_params.json. Saves out jpegs of contrasts. Uses MATLAB.
  - `prepare_data_run_pRF.m`: called by run_prf.sh, averages like-runs (wedgerings, bars), and calls prfVista()
  - `createmaps.m`: called by run_prf.sh, saves mgz files for prf estimates from results.mat file output from prfVista()
     - `natsort.m` : dependency for createmaps.m
  - `utils.sh`: script that loads modules, freesurfer license and conda dependencies based on whether on cluster.


## Dependencies:
- matlab (tested with 2021a) must be on the system path
- freesurfer (tested with 6.0.0)
  - freesurfer license must be at $FREESURFER_HOME/license.txt` (where $FREESURFER_HOME is an environmental variable specifying the path to the freesurfer application) or at the location specified by the environment variable `$FREESURFER_LICENSE`
- anaconda / miniconda (tested with anaconda3)
  - setup the `winawerlab` python environment, as described
    [here](https://wikis.nyu.edu/display/winawerlab/Python+and+Conda)
    You can set up in /scratch/$USER/environments/winawerlab
    (you can activate it using conda activate <path>, but you shouldn't need to if
    you use `masterScript.sh`, because we activate it there).
- [ToolboxToolbox](https://github.com/ToolboxHub/ToolboxToolbox), for managing
  matlab dependencies for GLM scripts using Winawerlab_NEI.json available on 
  [Winawer lab Toolbox Registry](https://github.com/WinawerLab/ToolboxRegistry).
  E.g., sets up MRI_tools, GLMsingle, fracridge, jsonlab, cvncode 
  See the [Winawer lab
  wiki](https://wikis.nyu.edu/display/winawerlab/ToolboxToolbox) for info on how
  to set it up.
- download the Winawer Lab
  [atlasmgz](https://github.com/WinawerLab/atlasmgz), 
  [prfVista](https://github.com/jankurzawski/prfVista), 
  [vistasoft](https://github.com/vistalab/vistasoft) 
  repos and make sure that they are in `NEI_analysis/`. They will be added to your path within the scripts.

```

- if you're running this on your local machine, then you should be good to go.
- if you're running this on a compute cluster that's not NYU's greene, then
  you'll need a couple more changes: you'll need to at least change:
  1. `Subroutines/utils.sh`: change `on_cluster()` function to something that
     will work for your cluster (note that we use `set -e pipefail`, so you
     can't rely on catching errors).
  2. `Subroutines/utils.sh`: check `load_modules()` and make sure the modules
     are correctly named. If your cluster uses some other command to handle
     packages, you'll have to change this more.
  3. `setup.sh`: check that the path `/scratch/$(whoami)` exists and that you
     have write access (and your cluster admin is okay with placing a lot of
     large files here).
