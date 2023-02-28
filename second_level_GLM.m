%% Enter info about data
%directory that contains contrast files
conFolder = @(P) ['D:\Data\HOHMB\P' num2str(P) '\model'];
%list of participant numbers
Ps = [1:12 14:18];
%desired name of folders for group contrast (should exist before running script)
groupFolders = {'D:\Data\HOHMB\Group_Spatial_Color_GLM'};
%name of con files to run t-test on (files in "conFolder")
cons = {'con_0001.nii'};

%% Run second-level model specification

for con = 1:length(cons)
    
    matlabbatch = {};
    
    conFiles = [];
    %select each subject's con file
    for P = Ps
        cd(conFolder(P));
        currentFolder = pwd;
        [files,dirs] = spm_select('List',currentFolder,['^' cons(con) '$']);
        conFiles = [conFiles; {[currentFolder '\' files]}];
    end
    
    
    %enter options for model specification
    matlabbatch{1}.spm.stats.factorial_design.dir = {groupFolder(con)};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = cellstr(conFiles);
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);
    
end

disp('Model specification done');

%% run estimation

for con = 1:length(cons)
   
    matlabbatch = {};
    
    %Select SPM.mat file and other default options
    matlabbatch{1}.spm.stats.fmri_est.spmmat = {[groupFolder(con) '\SPM.mat']};
    matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
    
    %run estimation
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);
    
end

disp('Model estimation done');
