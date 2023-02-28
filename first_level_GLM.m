%directory to each participant's run folder (replace participant numbers and run names with num2str(P) and run_name)
runFolder = @(P, run_name) ['F:\Data\HOHMB\P' num2str(P) '\' run_name];
%run names
runs = {'run1'; 'run2'; 'run3'; 'run4'; 'run5'; 'run6'};
%directory that contains stimulus info (replace participant numbers and run names with num2str(P) and run_name)
conditions = @(P,run_name) ['D:\Data\HOHMB\sub' num2str(P) '\behavior\hohm' num2str(P) '_' run_name '_submem.mat'];
%directory to save first level model
modelDir = @(P) ['D:\Data\HOHMB\sub' num2str(P) '\model'];
%TR in seconds
TR = 2;
%Reference slice (image at t=0)
refSlice = 1;
%list of participant numbers
Ps = [1:12 14:18];

%% Specify first-level model
for P = Ps
    
    %make a model folder in Subject folder
    mkdir modelDir
    
    matlabbatch = {};
    session_num = 1;
    for run = runs
        
        % change directory to run folder
        cd(runFolder(P,run));
        currentFolder = pwd;
        
        % grab motion realignment parameters to include as nuisence regressors
        [file,dirs] = spm_select('List',currentFolder,['^rp_a.*\.txt$']);
        motion_regs = [currentFolder '\' file];
        
        %specify condition information
        condition = conditions(P,run);
        
        %get images from this run and select
        [files,dirs] = spm_select('List',currentFolder,['^wra.*\.nii$']);
        Images = [[repmat(currentFolder,size(files,1),1) repmat('\',size(files,1),1) files]];
        selected = cellstr(Images);
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(session_num).scans = selected;
        matlabbatch{1}.spm.stats.fmri_spec.sess(session_num).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(session_num).multi = {condition};
        matlabbatch{1}.spm.stats.fmri_spec.sess(session_num).regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(session_num).multi_reg = {motion_regs};
        matlabbatch{1}.spm.stats.fmri_spec.sess(session_num).hpf = 128;
        
        session_num = session_num + 1;
    end
    
    %Enter all other default specifications
    matlabbatch{1}.spm.stats.fmri_spec.dir = {modelDir(P)};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'scans';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = refSlice;
    
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    
    %run model specification
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);
    
    disp(['Participant ' num2str(Ps(P)) ' model specification done.']);
end

disp('Model specification done');

%% Run Estimation to create beta weights

for P = Ps
   
    matlabbatch = {};
    % change directory to model folder
    cd(modelDir(P));
    currentFolder = pwd;
    
    %Select SPM.mat file and enter other default options
    matlabbatch{1}.spm.stats.fmri_est.spmmat = {[currentFolder '\SPM.mat']};
    matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
    
    %run estimation
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);
    disp(['Participant ' num2str(Ps(P)) ' model estimation done.']); 
end

disp('Model estimation done');