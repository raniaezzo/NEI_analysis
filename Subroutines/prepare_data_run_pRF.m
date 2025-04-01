% To create data files, load stim files and run prf fitting
disp('Starting prepare_data_run_pRF.m')

%tbUse WinawerLab_NEI;

projectDir = getenv('BIDS_DIR');
fsDir = getenv('SUBJECTS_DIR');
codeDir = getenv('CODE_DIR'); 
subject = getenv('SUBJECT_ID');
session = getenv('SESSION_ID');
protocol = getenv('PROTOCOL'); 
addpath(genpath(fullfile(codeDir)));

addpath(genpath(fullfile(codeDir, 'prfVista')));
addpath(genpath(fullfile(codeDir, 'vistasoft')));

hemi = {'L';'R'};

current_path = pwd
target_path = fullfile(projectDir, 'derivatives', 'fmriprep', sprintf('sub-%s',subject), sprintf('ses-%s',session), 'func')
cd(target_path)
disp(pwd)

A = [];
if isempty(A)
	prf_path = dir('./func/*task-wedgering*.gii')
        A = {prf_path.folder}
        A = unique(A)
end

tasks = {'bar1';'bar2';'bar3';'wedgering1';'wedgering2';'wedgering3'}


for t = 1 : length(tasks)
    for h = 1 : length(hemi)

        disp(sprintf('%s/*task-%s_hemi-%s_space-fsnative_bold.func.gii',target_path,tasks{t},hemi{h}))
        d = dir(sprintf('%s/*task-%s_hemi-%s_space-fsnative_bold.func.gii',target_path,tasks{t},hemi{h}))

        [~, fname] = fileparts(d.name);
        mynames{t,h} = sprintf('%s/%s.mgz',target_path,fname)
        str = sprintf('mri_convert %s/%s.gii %s/%s.mgz',target_path,fname,target_path,fname);
        system(str);

    end
end

datafiles_all = cell(length(mynames),1);

for f = 1 : length(mynames)
    
    data = [];
    for h = 1 : length(hemi)
        
       	tmp = MRIread(mynames{f,h});
        data = cat(1,data,squeeze(tmp.vol));
        
    end
    datafiles_all{f} = data;
end

% make derivatives/prfvista/ directory
prfpath = fullfile(projectDir, 'derivatives', 'prfvista', sprintf('sub-%s',subject));
mkdir(prfpath)

datafiles{1} = nanmean(cat(3,datafiles_all{1},datafiles_all{2},datafiles_all{3}),3);
datafiles{2} = nanmean(cat(3,datafiles_all{4},datafiles_all{5},datafiles_all{6}),3);

save(sprintf('%s/datafiles.mat',prfpath),'datafiles','-v7.3')
system(sprintf('chmod 770 %s', fullfile(prfpath, 'datafiles.mat')));

disp('Done converting giftis to mgz and averaging like-runs.');

warning off

% prepare for running vistasoft

tmpdir = fullfile(projectDir, 'derivatives', 'logs', sprintf('sub-', subject), 'tmp');
mkdir(tmpdir);
setenv('TMPDIR', tmpdir);
cache_dir = fullfile(projectDir, 'derivatives', 'logs', sprintf('sub-', subject));
setenv('MCR_CACHE_ROOT',cache_dir)

% load in stim file from main directory
stim1 = load(fullfile(projectDir, 'derivatives', 'stim_apertures', 'bars_nyu_small.mat'));
stim2 = load(fullfile(projectDir, 'derivatives', 'stim_apertures', 'ringswedge_nyu_small.mat'));
stim{1} = stim1.stimulus;
stim{2} = stim2.stimulus;

% save stim apertures to subjects prf directory
save(fullfile(prfpath, 'stimfiles.mat'), 'stim');
system(sprintf('chmod 770 %s', fullfile(prfpath, 'stimfiles.mat')));

jsonData = jsondecode(fileread(fullfile(codeDir, 'retmap_params.json')));
tr = jsonData.parameters.tr
stimradius = jsonData.parameters.stimradius

results = prfVistasoft(stim,datafiles,stimradius,'tr',tr,'wsearch','coarse to fine and hrf');
save(sprintf('%s/results.mat',prfpath),'results','-v7.3');

disp('Done with prfvista.')
