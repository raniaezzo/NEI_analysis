- As of now, if masterScript.sh is called with '-subjects all' flag, it will re-run even if already processed. Do we want this?
- Confirm retinotopy stimulus aperture is radius of 12.2
- Create new toolboxtoolbox registry for retinotopy and include:
   vistasoft: [https://github.com/vistalab/vistasoft]
   prfVista: [https://github.com/jankurzawski/prfVista/]
  *Note: prfVista is forked and differs from main branch--this forked version is correct.
- Find solution: atlasmgz git folder is not updated automatically right now, so requires git pull when necessary. It is on tb registry but b/c .sh script this is not useful as a matlab dependency.
- Combine log files per job. Now multiple log files are generated per job which makes it more complicated to debug.
- Remove git folder in Code folder that are not necessary b/c called with tbUse: fracridge, GLMdenoise, GLMsingle
- Move code from NEI_analysis/ into Code/ folder
- Incorporate fmriprep into masterScript - all jobs should depend on its completion.
- createmaps.m for the retinotopy saves polar angle in 2 ways angle.mgz (0 to pi for upperVF and 0 to -pi for lowerVF) and angle_adj.mgz (0 to -180 for leftVF and 0 to 180 for rightVF). Should we save from 0-360 as well?
- Transfer git repo to Winawerlab
- sub-wlsubj157: fMRIprep seems to have only been run on 1 session instead of 1-2
