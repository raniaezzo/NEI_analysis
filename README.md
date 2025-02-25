# NEI_fitGLM

Code related to the processing of localizers floc and mloc in NEI dataset

You can set the directory to put all data and analyses in by passing a path to
any of the main scripts. Alternatively, if they're called with no arguments, the
data directory is set to `NEI_analyzeLocalizers/` within this directory or
`/scratch/projects/corevisiongrantnei` if the `$CLUSTER` environmental
variable is equal to `GREENE` (and thus we think we're on NYU's greene cluster);
ideally this would be a general solution for different compute clusters, but we
couldn't come up with one.

Main scripts:
- `masterScriptGLM.sh`: checks for dependencies (matlab, freesurfer license, python
environment) and calls the rest of the scripts in this section, in order. Takes
a very long time, so you may want to call each section separately (which will
also ease debugging).
- `run_glm_single.sh`: runs
  [GLMsingle](https://github.com/cvnlab/GLMsingle) on the preprocessed
  data (just the `floc` and `mloc` tasks), estimating the response of each voxel per trial. Uses MATLAB.
- `setup.sh`: called at the beginning of each script to set environmental
  variables to make sure we get paths correct.

Sub-scripts:
- `subroutines/`, contains helper scripts used by the main scripts:
  - `run_glm_single.m`: actually calls GLMsingle on the data, after setting the
    various arguments. Saves out many images for examining the quality of the
    fit. Uses MATLAB, python, and the Winawer Lab `MRI_tools` repo (see below).
  - `writeContrastMaps.m`: generates mgz for each beta and contrasts of interest as defined in localizers_params.json. Saves out jpegs of contrasts. Uses MATLAB.

## Dependencies:
- matlab (version??) must be on the system path (MATLAB 9.6?)
- [ToolboxToolbox](https://github.com/ToolboxHub/ToolboxToolbox), for managing
  matlab dependencies. See the [Winawer lab
  wiki](https://wikis.nyu.edu/display/winawerlab/ToolboxToolbox) for info on how
  to set it up.
  - [Winawer lab Toolbox
    Registry](https://github.com/WinawerLab/ToolboxRegistry).
- freesurfer license must be at $FREESURFER_HOME/license.txt` (where $FREESURFER_HOME is an environmental variable specifying the path to the freesurfer application) or at the location specified by the environmental variable `$FREESURFER_LICENSE`
- setup the `winawerlab` python environment, as described
  [here](https://wikis.nyu.edu/display/winawerlab/Python+and+Conda)
  (you can activate it, following step 4, but you shouldn't need to if
  you use `masterScript.sh`, because we activate it there).
- download the Winawer Lab
  [MRI_tools](https://github.com/WinawerLab/MRI_tools) repo and make
  sure that its `BIDS` folder is on your path. One way to do this,
  from the command line, is (note this will only last for this
  session, if you want to permanently add that folder to your path,
  add the last line to your `~/.bashrc` file):

```
# download the repo
git clone git@github.com:WinawerLab/MRI_tools.git ~/Documents/MRI_tools
# add it to your path
export PATH="$HOME/Documents/MRI_tools/BIDS/:$PATH"
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
     large files here). If not, change `$SAMPLE_DATA_DIR` to some other path (in
     the first if block at the top of the file) or pass a path to the scripts
     when calling them..
