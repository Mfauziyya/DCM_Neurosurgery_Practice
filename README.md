# Semi-automated Pipeline for Structural Analysis of Compressed Spinal Cord in DCM

## Description

This repository contains the code for pre-processing structural T2-weighted, T2-star, and magnetization transfer MRI images. The primary goal is to estimate biomarkers such as spinal cord atrophy, gray matter atrophy, and white matter injury in patients with degenerative cervical myelopathy (DCM). This pipeline is designed to provide reproducible, standardized, and localized measures of spinal cord injury.
## Objectives

1. Reproducible Analysis Pipeline: A user-friendly pipeline for batch processing of spinal cord morphometrics.
2. Standardized Measures: Generate standardized and normalized morphometric using the PAM50 spinal cord template measures for comparison between patients and controls.
3. Clinical Insight: Provide clinical insights into white matter changes, with magnetization transfer (MT) being particularly sensitive to white matter changes in non-compressed regions.
4. Localized Evaluation: Provide spinal cord level-specific metrics to enable precise localization of spinal cord pathology.

### About the OU Spine Dataset

The OU Spine dataset was acquired using the https://spine-generic.readthedocs.io. The study is ongoing, involving patients diagnosed with DCM and a control cohort of healthy subjects (HC). All MRI scans were acquired using a 3T MR750 GE scanner.

Due to the ongoing nature of the study, patient data is still being collected and analyzed. However, sample patient and control data are available. Full datasets are available upon reasonable request to the senior author.

### Data Format and Organization
- All MRI datasets were converted from DICOM to NIFTI format and are organized following the Brain Imaging Data Structure (BIDS) format.
- Spinal cord files are renamed according to BIDS standard https://bids.neuroimaging.io.

### Dependencies
- Spinal Cord Toolbox (SCT 6.1): Required for spinal cord segmentation and analysis.
- Python 3.9: The processing scripts written in Python.
- FSLeyes (FMRIB Software Library): Required for data visualization.

## Installation
- Spinal Cord Toolbox, SCT 6.1: Follow the SCT installation guide for instructions on how to download and install SCT, and integrate it with FSL. https://spinalcordtoolbox.com/user_section/installation/mac.html
- Install script
    ```bash
    install_sct-<version>_macos.sh
    ```
- Python Environment:
    - Install the necessary Python dependencies listed in the requirements.txt file.

## Analysis Directory Setup
- Create a directory for processing and organize all input files as per the BIDS format.
### Usage
- Run the provided preprocessing script in batch mode.
```bash
    sct_run_batch -h
```
- This is the processing script that loops across all participant data. use the help message to include the mandatory and optional arguments.

#### example batch command
```bash
sct_run_batch -path-data /define/your/data/directory/sourcedata/ -jobs 50 -path-output /define/your/analysis/folder -script /specify/your/code/location/Preprocession_extraction.sh -exclude-list [ ses-brain ]
```

### Preprocessing Steps
Spinal Cord MRI (T2 weighted, T2 star, MT) preprocessing include number of key steps 
#### T2 weighted
1. Spinal cord Segmentation
```bash
    sct_deepseg_sc -i ${file}.nii.gz -c t2 -qc qc
```
-    To segment the cervical spinal cord from surrounding neck tissues.
-    include the qc flag to generate QC report for this step
2. Vertebral labeling
```bash
   sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg}.nii.gz -c t2 -qc qc
```
3. Registration to PAM50 template 
```bash
    sct_register_to_template -i ${file_t2w}.nii.gz -s ${file_t2_seg}.nii.gz -ldisc ${file_t2_labels_discs}.nii.gz -c t2 -qc qc
```
## Quality Control:
- After preprocessing, perform a QC check by reviewing the HTML files in the QC directory.
- Inspect the T2-weighted and T2-star images for segmentation and vertebral level labeling errors.
- If errors (e.g., segmentation leakage or under-segmentation) and/or labelling error are found, manually correct them.
- After corrections, re-run the batch analysis. The pipeline will automatically fetch manually corrected files from the designated folder(./BIDS/derivatives/label).
## Result Export:
o	The final morphometric measures will be exported to a CSV file.
o	The CSV file can be used for secondary analysis to evaluate metrics such as spinal cord shape, gray matter segmentation, white matter intensity, MTR (Magnetization Transfer Ratio), etc.

### Spinal Cord Analysis

This project processes spinal cord MRI images

![Spinal Cord Scan](./images/spinal_cord.png)
<img src="./images/spinal_cord.png" alt="Spinal Cord Scan" width="250">


