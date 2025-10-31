% To save out mgz files from prfvista output
disp('Starting createmaps.m')

%tbUse WinawerLab_NEI;

projectDir = getenv('BIDS_DIR');
fsDir = getenv('SUBJECTS_DIR');
codeDir = getenv('CODE_DIR'); 
subject = getenv('SUBJECT_ID');
session = getenv('SESSION_ID');
protocol = getenv('PROTOCOL'); 
addpath(genpath(fullfile(codeDir)));

fspth = fullfile(projectDir, 'derivatives', 'freesurfer', ['sub-' subject]);
prfpath = fullfile(projectDir, 'derivatives', 'prfvista', ['sub-' subject]);

disp(prfpath)

mgz = MRIread(fullfile(fspth, 'mri', 'orig.mgz'));

lcurv = read_curv(fullfile(fspth, 'surf', 'lh.curv'));
rcurv = read_curv(fullfile(fspth, 'surf', 'rh.curv'));

leftidx  = 1:numel(lcurv);
rightidx = (1:numel(rcurv))+numel(lcurv);

hemi{1} = zeros(length(lcurv),1);
hemi{2} = zeros(length(rcurv),1);

d = dir(sprintf('%s/*results*',prfpath))
files = natsort({d.name})

ssigma = [];
vvexpl = [];
aangle = [];
aangle_adj = [];
eeccen = [];
xx = [];
yy = [];

disp(length(files))

for f = 1 : length(files)

    tmp = load(sprintf('%s/%s',prfpath,files{f}));

    mysigma = tmp.results.model{1}.sigma.major;
    myvexpl = 1 - (tmp.results.model{1}.rss ./ tmp.results.model{1}.rawrss);
    myangle = atan2(-tmp.results.model{1}.y0,tmp.results.model{1}.x0);
    myangle_adj = (mod(90 - 180/pi * myangle + 180, 360) - 180);

    myx     = tmp.results.model{1}.x0;
    myy     = tmp.results.model{1}.y0;
    myeccen =  sqrt(tmp.results.model{1}.x0.^2+tmp.results.model{1}.y0.^2);

    ssigma = [ssigma mysigma];
    vvexpl = [vvexpl myvexpl];
    aangle = [aangle myangle];
    aangle_adj = [aangle_adj myangle_adj];
    xx = [xx myx];
    yy = [yy myy];
    eeccen = [eeccen myeccen];

end

mgz.vol = aangle(leftidx);
MRIwrite(mgz, fullfile(prfpath, 'lh.angle.mgz'));
mgz.vol = aangle(rightidx);
MRIwrite(mgz, fullfile(prfpath, 'rh.angle.mgz'));

mgz.vol = aangle_adj(leftidx);
MRIwrite(mgz, fullfile(prfpath, 'lh.angle_adj.mgz'));

mgz.vol = aangle_adj(rightidx);
MRIwrite(mgz, fullfile(prfpath, 'rh.angle_adj.mgz'));

mgz.vol = eeccen(leftidx);
MRIwrite(mgz, fullfile(prfpath, 'lh.eccen.mgz'));
mgz.vol = eeccen(rightidx);
MRIwrite(mgz, fullfile(prfpath, 'rh.eccen.mgz'));

mgz.vol = ssigma(leftidx);
MRIwrite(mgz, fullfile(prfpath, 'lh.sigma.mgz'));
mgz.vol = ssigma(rightidx);
MRIwrite(mgz, fullfile(prfpath, 'rh.sigma.mgz'));

% r2 (convert from percentage to fraction)
mgz.vol = vvexpl(leftidx);
MRIwrite(mgz, fullfile(prfpath, 'lh.vexpl.mgz'));
mgz.vol = vvexpl(rightidx);
MRIwrite(mgz, fullfile(prfpath, 'rh.vexpl.mgz'));

mgz.vol = xx(leftidx);
MRIwrite(mgz, fullfile(prfpath, 'lh.x.mgz'));
mgz.vol = xx(rightidx);
MRIwrite(mgz, fullfile(prfpath, 'rh.x.mgz'));

mgz.vol = yy(leftidx);
MRIwrite(mgz, fullfile(prfpath, 'lh.y.mgz'));
mgz.vol = yy(rightidx);
MRIwrite(mgz, fullfile(prfpath, 'rh.y.mgz'));
