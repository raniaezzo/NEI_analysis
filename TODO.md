- Create new toolboxtoolbox registry for retinotopy and include:
   vistasoft: [https://github.com/vistalab/vistasoft]
   prfVista: [https://github.com/jankurzawski/prfVista/]
  *Note: prfVista is forked and differs from main branch
- Find solution: atlasmgz git folder is not updated automatically right now, so requires git pull when necessary. It is on tb registry but b/c .sh script this is not useful as a matlab dependency.
- Combine log files per job. Now multiple log files are generated per job which makes it more complicated to debug.
- Remove git folder in Code folder that are not necessary b/c called with tbUse: fracridge, GLMdenoise, GLMsingle
- Move code from NEI_analysis/ into Code/ folder
- Incorporate fmriprep into masterScript - all jobs should depend on its completion.
