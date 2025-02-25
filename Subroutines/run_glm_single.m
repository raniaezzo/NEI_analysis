% To run GLM denoise on sample data
disp('Starting run_glm_single.m')

tbUse WinawerLab_NEI;

% %for now, just load in the repos needed b/c I am modifying them locally
% freesurferDir = '/Applications/freesurfer/7.2.0';
% PATH = getenv('PATH'); setenv('PATH', [PATH ':' freesurferDir '/bin']); % add freesurfer/bin to path
% setenv('FREESURFER_HOME', freesurferDir);
% addpath(genpath(fullfile(freesurferDir, 'matlab')));
% projectDir = '/Users/rje257/Desktop/transfer_gate/NEI_BIDS/';
% codeDir = '/Users/rje257/Documents/GitHub/NEI_fitGLM/'; 
% subject = 'wlsubj127';
% session = 'nyu3t02';
% protocol = 'mloc'; %'floc'; %
% addpath(genpath(codeDir)); 

% % % % % % addpath(genpath(fullfile(githubDir, 'MRI_tools'))); % https://github.com/WinawerLab/MRI_tools
% % % % % % addpath(genpath(fullfile(githubDir, 'GLMsingle'))); % https://github.com/cvnlab/GLMsingle
% % % % % % addpath(genpath(fullfile(githubDir, 'cvncode'))); 

% % Convert gifti files to mgz files (PUT BACK LATER)
projectDir = getenv('BIDS_DIR');
fsDir = getenv('SUBJECTS_DIR');
codeDir = getenv('CODE_DIR'); 
subject = getenv('SUBJECT_ID');
session = getenv('SESSION_ID');
protocol = getenv('PROTOCOL'); 
addpath(genpath(fullfile(codeDir)));

% load in the json with protocol params
jsonText = fileread(fullfile(codeDir, 'localizers_params.json'));
localizers_params = jsondecode(jsonText);

assert(exist(projectDir, 'dir')>0);

cd (fullfile(projectDir, 'derivatives', 'fmriprep',sprintf('sub-%s', subject), ...
    sprintf('ses-%s', session), 'func'));

% finds the gifti files
d = dir('./*fsnative*.gii');

% convert to mgz using freesurfer
for ii = 1:length(d)
    [~, fname] = fileparts(d(ii).name);
    str = sprintf('mri_convert %s.gii %s.mgz', fname, fname);
    if ~isfile(strcat(fname, '.mgz'))
        system(str);
    end
end

% 3. GLM denoise
tasks             = localizers_params.protocols.(protocol).bids_task_name;
stimdur           = localizers_params.protocols.(protocol).stimdur_s;
runnums           = [];
dataFolder        = 'fmriprep';
dataStr           = 'fsnative*mgz';
designFolder      = []; %sprintf('stim_%s', protocol); %'single_event';
modelType         = [];                           %'shortblocks';
glmOptsPath       = [];
tr                = [];
disp('Done setting params in run_glm_single.m')

% run the GLM
bidsGLM(projectDir, subject, session, tasks, runnums, ...
    dataFolder, dataStr, designFolder, stimdur, modelType, glmOptsPath, tr)
disp('Done with bidsGLM in run_glm_single.m')

% To get images of the GLM denoise output, run the following python command 
pngprocess = which('GLMdenoisePNGprocess.py');
figurepth  = fullfile(projectDir, 'derivatives', 'GLMsingle', modelType, ...
    sprintf('sub-%s', subject), sprintf('ses-%s', session), tasks);
system(sprintf('python %s %s', pngprocess, figurepth));

% To generate beta and contrast surface mgzs and pngs
%writeContrastMaps()
%disp('Done writing contrast PNGs in run_glm_single.m')

