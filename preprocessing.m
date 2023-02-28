%% Enter info about data and preprocessing parameters
%directory to each participant's run folder (replace participant numbers and run names with num2str(P) and run_name)
runFolder = @(P, run_name) ['F:\Data\HOHMB\P' num2str(P) '\' run_name];
%list of participant numbers
Ps = [1:12 14:18];
%run names
runs = {'run1'; 'run2'; 'run3'; 'run4'; 'run5'; 'run6'};
%directory to each participant's anatomic folder
anatFolder = @(P) ['F:\Data\HOHMB\P' num2str(P) '\anatomic'];
%desired name for group average anatomic image
av_anat_name = 'HOHM_group_anat';
%number of slices per functional image
nSlices = 33;
%chronological order of slices
sliceOrder = [1:2:nSlices 2:2:nSlices];
%TR in seconds
TR = 2;
%TA = TR-(TR/(nSlices/MB_factor))
TA = 2-(2/33);
%Reference slice for slice timing (image at t=0)
refSlice = 1;
%size of voxels for normalization
voxSize = [2 2 2];
anatVoxSize = [1 1 1];
%FWHM in mm for smoothing kernel
FWHM = [3 3 3];

%paths to SPM12 functions and project-specific scripts
spm_path = 'F:\Data\spm12';
scripts_path = 'F:\Data\HOHMB\scripts';
addpath(spm_path,scripts_path)
%initialize SPM
spm('defaults','FMRI')
spm_jobman('initcfg')


%% Normalize anatomic images and create group average

for P = 1:length(Ps)
    
    % change directory to participant's anatomic folder
    cd(anatFolder(Ps(P)));
    currentFolder = pwd;
    
    %initialize batch and image variables
    matlabbatch = {};
    niiImage = [];
    
    %get images from this run and put them in session matrix
    [file,dirs] = spm_select('List',currentFolder,['.*\.nii$']);
    niiImage = [currentFolder '/' file];
    
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.vol = {niiImage};
    
    selected = cellstr(niiImage);
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = selected;
    
    %enter all standard options for normalization
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {[spm_path '\tpm\TPM.nii']};
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.bb = [-78 -112 -70
        78 76 85];
    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.vox = anatVoxSize;
    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.interp = 4;
    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.prefix = 'w';
    
    
    %run batch and normalize images
    spm('defaults', 'FMRI');
    spm_jobman('run',matlabbatch);
    disp(['Participant ' num2str(Ps(P)) ' anatomic normalization done.']);
end

%Average anatomic images
matlabbatch = {};
niiImages = [];

for P = 1:length(Ps)
    
    % change directory to participant's anatomic folder
    cd(anatFolder(Ps(P)));
    currentFolder = pwd;
    % select normalized anatomic image and add to list
    [file,dirs] = spm_select('List',currentFolder,['^w' num2str(Ps(P)) '.*\.nii$']);
    niiImages = [niiImages; currentFolder '/' file];
end

%set up batch to calculate average image
selected = cellstr(niiImages);
matlabbatch{1}.spm.util.imcalc.input = selected;
matlabbatch{1}.spm.util.imcalc.output = av_anat_name;
matlabbatch{1}.spm.util.imcalc.outdir = {scripts_path};
matlabbatch{1}.spm.util.imcalc.expression = 'mean(X)';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 1;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

%run batch
spm('defaults', 'FMRI');
spm_jobman('run',matlabbatch);
disp(['Group anatomic average image created.']);

%% Slice Time Correction
% files should be f*.nii
% will convert files to a* files.


for P = 1:length(Ps)
    
    matlabbatch = {};
    fImages = [];
    selected = {};
    
        
    for run = 1:length(runs)
        
        % change directory to run folder
        cd(runFolder(Ps(P),runs{run}));
        currentFolder = pwd;
        
        %get images from this run and add to list of all images
        [files,dirs] = spm_select('List',currentFolder,['^f.*\.nii$']);
        fImages = [fImages; [repmat(currentFolder,size(files,1),1) repmat('/',size(files,1),1) files]];
        % display number of images in run (to double check and ensure accuracy)
        disp(['Run ' num2str(run) ' has ' num2str(size(files,1)) ' images.']);
        
    end
    % display number of total images for participant(to double check and ensure accuracy)
    disp(['Participant ' num2str(Ps(P)) ' has ' num2str(size(fImages,1)) ' images.']);
    
    %select all images for slice timing
    selected(1) = {cellstr(fImages)};
    matlabbatch{1}.spm.temporal.st.scans = selected;
    
    %input options for slice timing
    matlabbatch{1}.spm.temporal.st.nslices = nSlices;
    matlabbatch{1}.spm.temporal.st.tr = TR;
    matlabbatch{1}.spm.temporal.st.ta = TA;
    matlabbatch{1}.spm.temporal.st.so = acq_times;
    matlabbatch{1}.spm.temporal.st.refslice = refSlice;
    matlabbatch{1}.spm.temporal.st.prefix = 'a';
    
    %run slice timing
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);
    disp(['Participant ' num2str(Ps(P)) ' slice time correction done.']);
    
end

disp('Slice timing done');

%% Motion Correction
%files should be af*.nii
%files will be converted to raf*.nii


for P = 1:length(Ps)
    
    %initialize spm graphics window, so motion correction figure is saved
    spm_figure('GetWin','Graphics');
    matlabbatch = {};
    afImages = {};
    
    for run = 1:length(runs)
        
        % change directory to run folder
        cd(runFolder(Ps(P),runs{run}));
        currentFolder = pwd;
        
        %get images from this run and put them in session cell array
        [files,dirs] = spm_select('List',currentFolder,['^af.*\.nii$']);
        session = [repmat(currentFolder,size(files,1),1) repmat('/',size(files,1),1) files];
        session = cellstr(session);
        
        % display number of images in run (to double check and ensure accuracy)
        disp(['Participant ' num2str(Ps(P)) ' Run ' num2str(run) ' has ' num2str(size(files,1)) ' images.']);
        %put session cell into cell array
        afImages(run) = {session};
        
    end
    
    %select all images from all sessions
    matlabbatch{1}.spm.spatial.realign.estwrite.data = afImages(~cellfun('isempty',afImages));
    %enter all standard options for motion correction
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 2;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 1];
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
    
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);
    disp(['Participant ' num2str(Ps(P)) ' motion correction done.']);
end
disp('Motion correction done');

%% Normalize
%files should be raf*.nii
%files will be converted to wraf*.nii


for P = 1:length(Ps)
    matlabbatch = {};
    rafImages = [];
    
    for run = 1:length(runs)
        
        % change directory to run folder
        cd(runFolder(Ps(P),runs{run}));
        currentFolder = pwd;
        
        %get images from this run and put them in session matrix
        [files,dirs] = spm_select('List',currentFolder,['^raf.*\.nii$']);
        rafImages = [rafImages; [repmat(currentFolder,size(files,1),1) repmat('/',size(files,1),1) files]];
        % display number of images in run (to double check and ensure accuracy)
        disp(['Run ' num2str(run) ' has ' num2str(size(files,1)) ' images.']);
        % select first image of first run as image to normalize to
        if run == 1
            first = spm_select('List',currentFolder,['^ra.*\1-01.nii$']);
            matlabbatch{1}.spm.spatial.normalise.estwrite.subj.vol = {[currentFolder '/' first]};
        end
        
    end
    
    %select all participant files as images to write
    selected = cellstr(rafImages);
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = selected;
    %enter all standard options for normalization
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {spm_path '\tpm\TPM.nii'};
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.bb = [-78 -112 -70
        78 76 85];
    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.vox = voxSize;
    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.interp = 4;
    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.prefix = 'w';
    
    
    %run batch and normalize images
    spm('defaults', 'FMRI');
    spm_jobman('run',matlabbatch);
    disp(['Participant ' num2str(Ps(P)) ' normalization done.']);
end

disp('Normalization done');

%% Smoothing
%files should be wraf*.nii
%files will be converted to swraf*.nii

for P = 1:length(Ps)
    matlabbatch = {};
    wrafImages = [];
    
    for run = 1:length(runs)
        
        % change directory to run folder
        cd(runFolder(Ps(P),runs{run}));
        currentFolder = pwd;
        
        %get images from this run and put them in session matrix
        [files,dirs] = spm_select('List',currentFolder,['^wraf.*\.nii$']);
        wrafImages = [wrafImages; [repmat(currentFolder,size(files,1),1) repmat('/',size(files,1),1) files]];
        % display number of images in run (to double check and ensure accuracy)
        disp(['Participant ' num2str(Ps(P)) ' run ' num2str(run) ' has ' num2str(size(files,1)) ' images.']);
        
    end
    
    %select all participant files as images to write and input parameters
    selected = cellstr(wrafImages);
    matlabbatch{1}.spm.spatial.smooth.data = selected;
    matlabbatch{1}.spm.spatial.smooth.fwhm = FWHM;
    matlabbatch{1}.spm.spatial.smooth.dtype = 0;
    matlabbatch{1}.spm.spatial.smooth.im = 0;
    matlabbatch{1}.spm.spatial.smooth.prefix = 's';
    
    
    %run batch and smooth images
    spm('defaults', 'FMRI');
    spm_jobman('run',matlabbatch);
    disp(['Participant ' num2str(Ps(P)) ' smoothing done.']);
end

disp('Smoothing done');
