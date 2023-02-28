# SPM_scripts
MATLAB scripts for pre-processing fMRI data and running GLM analysis with SPM

Project-specific parameters should be specified in the first section of each script before running

## Getting started
These scripts require the SPM12 software, which can be downloaded from https://www.fil.ion.ucl.ac.uk/spm/software/spm12/

Make sure to add SPM to your MATLAB path before running with 
```shell
addpath('path/to/SPM') 
```

fMRI data files should be in nifti format (i.e., file extension '.nii')

Before running the GLM scripts, condition files should be constructed for each participant, following the SPM12 manual guidelines (i.e., a cell array including event names, onsets, and durations) to allow for modeling of event-related activity

## Features

Description of each file
* preprocessing.m runs common fMRI data preprocessing pipeline (slice-time correction, motion correction, normalization to MNI template, and spatial smooting)
* first_level_GLM.m specifies and estimates a first-level general linear model for each participant
* second_level_GLM.m specifies and estimates a second-level t-test using the first-level GLM contrast files

## Configuration

The first section of each script contains the project-specific parameters that will need to specified to run the rest of the code. Subsequent sections run the described preprocessing and analysis pipelines and should not need to be edited unless a non-standard analysis is being conducted (i.e., you want to change the default settings). Descriptions of the project-specific parameters for each script are listed below.

### preprocessing.m
#### runFolder
Type: `inline function`     
Example: `@(P, run_name) ['F:\Data\HOHMB\P' num2str(P) '\' run_name]`       
directory to each participant's run folders (replace participant numbers and run names with num2str(P) and run_name)
#### Ps
Type: `numeric vector`  
Example: `[1 2 4 6:11]`     
numbers used to identify participants in directory and file names
#### runs
Type: `string` or `cell array of strings`   
Example: `{'run1', 'run2', 'run3'}`     
names used to identify data collection or task runs in directory
#### anatFolder
Type: `inline function`     
Example: `@(P) ['F:\Data\HOHMB\P' num2str(P) '\anatomic']`      
Directory to each participant's anatomic folder
#### av_anat_name 
Type: `string`  
Example: `HOHM_group_anatomic`      
desired output file name for group average anatomic image
#### nSlices
Type: `number`      
Example: `33`       
number of slices in each image (this can be determined by displaying a raw data file in SPM and looking at the image dimensions)
#### sliceOrder 
Type: `numeric vector`  
Example: `[1:2:nSlices 2:2:nSlices]` (Interleaved slice order from bottom to top)       
order of slices during data acquisition
#### TR
Type: `number`      
Example: `2`    
Time of Repetition in seconds 
#### TA
Type: `number` or `equation`    
Example: `2-(2/33)`     
Time of acquisition in seconds. Can be calculated by TA = TR-(TR/nSlices) or, if multiband imaging was used, TA = TR-(TR/(nSlices/MB_factor))
#### refSlice
Type: `number`      
Example: `1`        
Image number at time = 0
#### voxSize
Type: `1x3 numeric vector`      
Example: `[2 2 2]`      
size of normalized voxels in mm for functional images
#### anatVoxSize
Type: `1x3 numeric vector`      
Example: `[1 1 1]`      
size of normalized voxels in mm for anatomic images
#### FWHM
Type: `1x3 numeric vector`      
Example: `[3 3 3]`      
Full Width Half Maximum of the Gaussian smoothing kernel (mm)

### first_level_GLM.m
#### runFolder
Type: `inline function`     
Example: `@(P, run_name) ['F:\Data\HOHMB\P' num2str(P) '\' run_name];`      
directory to each participant's run folder (replace participant numbers and run names with num2str(P) and run_name)
#### runs
Type: `string` or `cell array of strings`       
Example: `{'run1', 'run2', 'run3'}`        
names used to identify data collection or task runs in directory
#### conditions
Type: `inline function`     
Example: `@(P,run_name) ['D:\Data\HOHMB\P' num2str(P) '\behavior\hohm' num2str(P) '_' run_name '_submem.mat']`     
Directory to the conditions file for each run of each participant
#### modelDir
Type: `inline function`     
Example: `@(P) ['D:\Data\HOHMB\P' num2str(P) '\model']`     
directory to save each participant's first level model
#### TR
Type: `number`      
Example: `2`    
Time of Repetition in seconds 
#### refSlice
Type: `number`      
Example: `1`        
Image number at time = 0
#### Ps
Type: `numeric vector`  
Example: `[1 2 4 6:11]`     
numbers used to identify participants in directory and file names

### second_level_GLM.m
#### conFolder
Type: `inline function`     
Example: `@(P) ['D:\Data\HOHMB\sub' num2str(P) '\model']`         
directory that contains contrast files from first-level GLM (usually the participant's model folder, unless you saved them somewhere else)
#### Ps
Type: `numeric vector`   
Example: `[1 2 4 6:11]`         
numbers used to identify participants in directory and file names
#### groupFolders
Type: `string` or `cell array of strings`   
Example: `{'D:\Data\HOHMB\Group_Spatial_Color_GLM'}`      
desired name of folders for group model output (should exist before running script)
#### cons
Type: `string` or `cell array of strings`   
Example: `{'con_0001.nii'}`     
name of con files to run t-test on (files in "conFolder")
