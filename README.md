# Semi-automated Pipeline for Structural Analysis of Compressed Spinal Cord in DCM

## Description

This repository contains the code for pre-processing structural T2-weighted, T2-star, and magnetization transfer MRI images. The primary goal is to estimate biomarkers such as spinal cord atrophy, gray matter atrophy, and white matter injury in patients with degenerative cervical myelopathy (DCM). This pipeline is designed to provide reproducible, standardized, and localized measures of spinal cord injury.
## Table of Contents
- [Objectives](#objectives)
- [About the OU Spine Dataset](#about-the-ou-spine-dataset)
- [Data Format and Organization](#data-format-and-organization)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Analysis Directory Setup](#analysis-directory-setup)
- [Quality Control](#quality-control)
- [Result Export](#result-export)
- [Publications](#publications)


### Objectives

1. Reproducible Analysis Pipeline: A user-friendly pipeline for batch processing of spinal cord morphometrics.
2. Standardized Measures: Generate standardized and normalized morphometric using the PAM50 spinal cord template measures for comparison between patients and controls.
3. Clinical Insight: Provide clinical insights into white matter changes, with magnetization transfer (MT) being particularly sensitive to white matter changes in non-compressed regions.
4. Localized Evaluation: Provide spinal cord level-specific metrics to enable precise localization of spinal cord pathology.

### About the OU Spine Dataset

The OU Spine dataset was acquired using the https://spine-generic.readthedocs.io. The study is ongoing, involving patients diagnosed with DCM and a control cohort of healthy subjects (HC). All MRI scans were acquired using a 3T MR750 GE scanner.
Due to the ongoing nature of the study, patient data is still being collected and analyzed. However, sample patient and control data are available in the Example data folder. Full datasets are available upon reasonable request to the senior author.

### Data Format and Organization
- All MRI datasets were converted from DICOM to NIFTI format and are organized following the Brain Imaging Data Structure (BIDS) format.
- Conversion command
 ```bash
     dcm2niix -f <output_directory/output_file_name> <input_directory> 
  ```
- Spinal cord files are renamed according to BIDS standard https://bids.neuroimaging.io.
Here is an example of our data organization
    ```bash
        OU_DCM_2024/data_processed/sub-CSM030
        ├── derivatives
        │   └── labels
        │       └── sub-CSM030
        │           └── ses-spinalcord
        │               └── anat
        │                   ├── sub-CSM030_ses-spinalcord_T2star.nii.gz
        │                   ├── sub-CSM030_ses-spinalcord_T2star_seg.nii.gz
        │                   ├── sub-CSM030_ses-spinalcord_T2w.nii.gz
        │                   ├── sub-CSM030_ses-spinalcord_T2w_label-compression-manual.nii.gz
        │                   ├── sub-CSM030_ses-spinalcord_T2w_seg.nii.gz
        │                   └── sub-CSM030_ses-spinalcord_acq-MTon_MTS_seg.nii.gz
        └── sourcedata
            └── sub-CSM030
                └── ses-spinalcord
                    └── anat
                        ├── sub-CSM030_ses-spinalcord_3DMAGiC.nii.gz
                        ├── sub-CSM030_ses-spinalcord_T2star.nii.gz
                        ├── sub-CSM030_ses-spinalcord_T2w.nii.gz
                        ├── sub-CSM030_ses-spinalcord_acq-MToff_MTS.json
                        ├── sub-CSM030_ses-spinalcord_acq-MToff_MTS.nii.gz
                        ├── sub-CSM030_ses-spinalcord_acq-MTon_MTS.json
                        ├── sub-CSM030_ses-spinalcord_acq-MTon_MTS.nii.gz
                        ├── sub-CSM030_ses-spinalcord_acq-T1w_MTS.json
                        └── sub-CSM030_ses-spinalcord_acq-T1w_MTS.nii.gz
    ```
### Dependencies
- Spinal Cord Toolbox (SCT 6.1): Required for spinal cord segmentation and analysis.
- Python 3.9: The processing scripts written in Python.
- FSLeyes (FMRIB Software Library): Required for data visualization.

## Installation
- Spinal Cord Toolbox, SCT 6.1: Follow the SCT installation guide for instructions on how to download and install SCT, and integrate it with FSL. https://spinalcordtoolbox.com/user_section/installation.html
- Install script for MacOS
    ```bash
     install_sct-<version>_macos.sh
    ```
- Python Environment:
    - Install the necessary Python dependencies listed in the requirements.txt file.

## Analysis Directory Setup
- Create a directory for processing and organize all input files as per the BIDS format.
- Spinal Cord Toolbox [(SCT 6.1)](https://github.com/spinalcordtoolbox/spinalcordtoolbox/releases/tag/6.1): Required   for spinal cord segmentation and analysis.
 - Python 3.9: The processing scripts written in Python. (or analysis scripts? I don't see it in your batch script)
 - [FSLeyes](https://open.win.ox.ac.uk/pages/fsl/fsleyes/fsleyes/userdoc/install.html) (FMRIB Software Library): Required for data visualization. (could be ITKsnap, 3Dslicer...)

 ### Installation
 - Spinal Cord Toolbox, [SCT 6.1](https://github.com/spinalcordtoolbox/spinalcordtoolbox/releases/tag/6.1) : Follow the SCT installation guide for instructions on how to download and install SCT script for version 6.1, and integrate it with FSL. [https://spinalcordtoolbox.com/user_section/installation.html](https://spinalcordtoolbox.com/en/stable/user_section/installation.html)


### Usage
- Run the provided preprocessing script in batch mode.
```bash
    sct_run_batch -h
```
- This is the processing script that loops across all participant data. Use the help message to include the mandatory and optional arguments.

#### Example command
```bash
sct_run_batch -path-data /define/your/data/directory/sourcedata/ -jobs 50 -path-output /define/your/analysis/folder -script /specify/your/code/location/Preprocession_extraction.sh -exclude-list [ ses-brain ]
```
 - `-path-data`: path to data folder to be processed in BIDS format.
 - `-jobs`: Number of subject to run in parallel.
 - `-path-output`: Path of analysis results.
 - `-script`: preprocessing script (`DCM_Neurosurgery_Practice/Scripts/Preprocession_extraction.sh`).
 - `-exclude-list`: list of subjects or session to exclude from the analysis.
 #### Note
 include the qc flag to generate the quality control report for this step


## Quality Control:
- After preprocessing, perform a QC check by reviewing the HTML files in the QC directory: `<path-out>/qc/index.html`.
- Inspect the T2-weighted and T2-star images for segmentation and vertebral level labeling errors:
- If errors (e.g., segmentation leakage or under-segmentation) and/or labelling error are found, manually correct them and save them under derivatives/label.
- After corrections, re-run the batch analysis. The pipeline will automatically fetch manually corrected files from the designated folder(./BIDS/derivatives/label).
## Result Export:
- Morphometric and MTR (Magnetization Transfer Ratio) measurements will be exported as CSV files.
- These CSV files can be used for secondary analysis to assess metrics such as  T2-weighted morphometrics (CSA,AP, RL, eccentricity, solidity, MSCC) as well as GM and WM morphometrics, including signal intensity, and tract- and region-based MTR.
- Additionally, the exported data can facilitate group analysis to compare cohorts.

## Publications

- Muhammad F, Weber KA, Bédard S, Haynes G, Smith L, Khan AF, Hameed S, Gray K, McGovern K, Rohan M, Ding L, Van Hal M, Dickson D, Al Tamimi M, Parrish T, Dhaher Y, Smith ZA. Cervical spinal cord morphometrics in degenerative cervical myelopathy: quantification using semi-automated normalized technique and correlation with neurological dysfunctions, The Spine Journal (2024), https://doi.org/10.1016/j.spinee.2024.07.002

- Haynes G, Muhammad F, Weber KA II, Khan AF, Hameed S, Shakir H, Van Hal M, Dickson D, Rohan M, Dhaher Y, Parrish T, Ding L, Smith ZA. Tract-specific magnetization transfer ratio provides insights into the severity of degenerative cervical myelopathy. Spinal Cord (2024). https://doi.org/10.1038/s41393-024-01036-y




