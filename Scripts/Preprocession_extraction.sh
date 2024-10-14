#!/bin/bash
# 
#
# Created by Ken Weber & Fauziyya 12/11/21.
# 
# Modified by Fauziyya Muhammad 11/15/23 using Spinalcord updatedd Command-Line Tools and Analysis Tutorials;https://spinalcordtoolbox.com/user_section/tutorials.html

# Usage:
# sct_run_batch  -path-data /Users/fmuhamma/Desktop/Mri/BIDS/sourcedata -jobs 1 -path-output  /Users/fmuhamma/Desktop/Mri/sc_analysis_dcm -script /Users/fmuhamma/Desktop/Mri/codes/preprocess_spinal_cord_new.sh -include-list [$subject_ID] exclude-list [$subject_ID]
# This above will set up the analysis pathway called sc_analysis_dcm in the Mri directory. 
# The following global variables are retrieved from the caller sct_run_batch:
# PATH_DATA_PROCESSED="~/data_processed"
# PATH_RESULTS="~/results"
# PATH_LOG="~/log"
# PATH_QC="~/qc"


# Uncomment for full verbose
set -x

# Immediately exit if error
set -e -o pipefail

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Print retrieved variables from sct_run_batch to the log (to allow easier debug)
echo "Retrieved variables from from the caller sct_run_batch:"
echo "PATH_DATA: ${PATH_DATA}"
echo "PATH_DATA_PROCESSED: ${PATH_DATA_PROCESSED}"
echo "PATH_RESULTS: ${PATH_RESULTS}"
echo "PATH_LOG: ${PATH_LOG}"
echo "PATH_QC: ${PATH_QC}"

# Get path derivatives
path_source=$(dirname $PATH_DATA)
PATH_DERIVATIVES="${path_source}/derivatives/labels"

# Get path of script repository
PATH_SCRIPTS=$PWD


# CONVENIENCE FUNCTIONS
# ======================================================================================================================
segment_if_does_not_exist() {
  ###
  #  This function checks if a manual spinal cord segmentation file already exists, then:
  #    - If it does, copy it locally.
  #    - If it doesn't, perform automatic spinal cord segmentation
  #  This allows you to add manual segmentations on a subject-by-subject basis without disrupting the pipeline.
  ###
  local file="$1"
  local contrast="$2"
  local segmentation_method="$3"  # deepseg or propseg
  local subfolder="$4"
  # Update global variable with segmentation file name
  FILESEG="${file}_seg"
  FILESEGMANUAL="${PATH_DERIVATIVES}/${SUBJECT}/anat/${FILESEG}.nii.gz" #finds the manual corrected file but the script doesn't progress.
  #FILESEGMANUAL="${PATH_DERIVATIVES}/${SUBJECT}/${SES}/anat/${FILESEG}.nii.gz"
  echo
  echo "Looking for manual segmentation: $FILESEGMANUAL"
  if [[ -e $FILESEGMANUAL ]]; then
    echo "Found! Using manual segmentation."
    rsync -avzh $FILESEGMANUAL ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject ${SUBJECT}
    # Rename manual seg to seg name
    mv ${FILESEG}.nii.gz ${file}_seg.nii.gz
  else
    echo "Not found. Proceeding with automatic segmentation."
    # Segment spinal cord
    if [[ $segmentation_method == 'deepseg' ]];then
        sct_deepseg_sc -i ${file}.nii.gz -c ${contrast} -qc ${PATH_QC} -qc-subject ${SUBJECT}
    elif [[ $segmentation_method == 'propseg' ]]; then
        sct_propseg -i ${file}.nii.gz -c ${contrast} -qc ${PATH_QC} -qc-subject ${SUBJECT} -CSF
    fi
  fi
}


label_if_does_not_exist(){
  ###
  #  This function checks if a manual labels exists, then:
  #    - If it does, copy it locally and use them to initialize vertebral labeling
  #    - If it doesn't, perform automatic vertebral labeling
  ###
  local file="$1"
  local file_seg="$2"
  # Update global variable with segmentation file name
  FILELABEL="${file}_labels-disc"
  FILELABELMANUAL="${PATH_DERIVATIVES}/${SUBJECT}/anat/${FILELABEL}-manual.nii.gz"
  echo "Looking for manual label: $FILELABELMANUAL"
  if [[ -e $FILELABELMANUAL ]]; then
    echo "Found! Using manual labels."
    rsync -avzh $FILELABELMANUAL ${FILELABEL}.nii.gz
    # Generate labeled segmentation from manual disc labels
    sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg}.nii.gz -discfile ${FILELABEL}.nii.gz -c t2 -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    echo "Not found. Proceeding with automatic labeling."
    # Generate vertebral labeling
    sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg}.nii.gz -c t2 -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}


# Check if manual segmentation already exists. If it does, copy it locally. If
# it does not, perform seg.
segment_gm_if_does_not_exist(){
  local file="$1"
  #local contrast="$2"
  # Update global variable with segmentation file name
  FILESEG="${file}_gmseg"
  FILESEGMANUAL="${PATH_DERIVATIVES}/${SUBJECT}/anat/${FILESEG}.nii.gz"
  echo "Looking for manual segmentation: $FILESEGMANUAL"
  if [[ -e $FILESEGMANUAL ]]; then
    echo "Found! Using manual segmentation."
    rsync -avzh $FILESEGMANUAL ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_gm -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    echo "Not found. Proceeding with automatic segmentation."
    # Segment spinal cord
    sct_deepseg_gm -i ${file}.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}


# Retrieve input params and other params
SUBJECT=$1
# Go to folder where data will be copied and processed # the Path_data created by sct-run batch
cd $PATH_DATA_PROCESSED

# Copy source images
# Note: we use '/./' in order to include the sub-folder 'ses-0X'
rsync -Ravzh $PATH_DATA/./$SUBJECT .

cd ${SUBJECT}/anat

# Define variables
# We do a substitution '/' --> '_' in case there is a subfolder 'ses-0X/'
file="${SUBJECT//[\/]/_}"

# Get session
SES=$(basename "$SUBJECT") 

# Only include spinal cord sessions
if [[ $SES == *"spinalcord"* ]];then
#<<comment

##################################################################
# Process T2w 
# This section will perform 
#-segmentation
#-labeling
# registration to PAM50 template space
#extraction of morphometrics
##################################################################

	# Add suffix corresponding to contrast
    file_t2w=${file}_T2w
    # Check if T2w image exists
    if [[ -f ${file_t2w}.nii.gz ]];then
        # Create directory for T2w results
        mkdir -p ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/T2w
        cp ${file_t2w}.nii.gz ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/T2w
        cd T2w
        
        # Spinal cord segmentation
        # Note: For T2w images, we use sct_deepseg_sc with 2 kernel. Generally, it works better than sct_propseg and sct_deepseg_sc with 3d kernel.
        segment_if_does_not_exist ${file_t2w} 't2' 'deepseg' 'anat'
        file_t2_seg="${file_t2w}_seg" #${file}_T2w_seg

        # Vertebral labeling 
        label_if_does_not_exist ${file_t2w} ${file_t2w}_seg
        file_t2_labels="${file_t2w}_seg_labeled"
        file_t2_labels_discs="${file_t2w}_seg_labeled_discs"


        # Extract disc 3 to 8 for registration to template (C1 to T1-T2)(*)
        sct_label_utils -i ${file_t2_labels_discs}.nii.gz -keep 1,2,3,4,5,6,7,8,9 -o ${file_t2_labels_discs}_1to9.nii.gz
        file_t2_labels_discs="${file_t2w}_seg_labeled_discs_1to9"

        # Compute CSA per level(*)
        sct_process_segmentation -i ${file_t2_seg}.nii.gz -vertfile ${file_t2_labels}.nii.gz -vert 2:8 -perlevel 1 -o t2w_shape_perlevel.csv -append 1
        
        # Compute CSA (and other morphometry measures) for each slice(*)
        sct_process_segmentation -i ${file_t2_seg}.nii.gz -o t2w_shape_perslice.csv -append 1 -perslice 1 -angle-corr 1 -vert 2:8 -vertfile ${file_t2_labels}.nii.gz
        #sct_process_segmentation -i ${file_t2_seg}.nii.gz -o ${PATH_RESULTS}/t2w_shape_perslice.csv -append 1 -perslice 1 -angle-corr 1 -vert 2:8 -vertfile ./label/template/PAM50_levels.nii.gz
        
        
        # Register T2w image to PAM50 template using all discs (C2-C3 to C7-T1)(*)
        sct_register_to_template -i ${file_t2w}.nii.gz -s ${file_t2_seg}.nii.gz -ldisc ${file_t2_labels_discs}.nii.gz -c t2 -qc ${PATH_QC} -qc-subject ${SUBJECT}
        
        # Warp template without the white matter atlas 
        sct_warp_template -d ${file_t2w}.nii.gz -w warp_template2anat.nii.gz  -qc ${PATH_QC} -qc-subject ${SUBJECT}
        
		# Compute morphometrics in PAM50 anatomical space perslice (*)
        sct_process_segmentation -i ${file_t2_seg}.nii.gz -vertfile ${file_t2_labels}.nii.gz -perslice 1 -normalize-PAM50 1 -v 2 -o t2w_shape_PAM50_perslice.csv -append 1
              
      
compression_if_does_not_exist() {
  	###
  	 #  This function checks if a manual spinal cord segmentation file already exists, then:
  	 #    - If it does, copy it locally.
 	 #    - If it doesn't, perform automatic spinal cord segmentation.
 	 #  This allows you to add manual segmentations on a subject-by-subject basis without disrupting the pipeline.
  	###
  local file="$1"
  local contrast="$2"
  local compute_compression_method="$3"  
  local subfolder="$4"
  # Update global variable with segmentation file name
  file_compression="${file_t2w}_label-compression-manual"
  file_t2_seg="${file_t2w}_seg"
  file_t2_labels="${file_t2w}_seg_labeled"
  FILE_COMPRESSION_MANUAL="${PATH_DERIVATIVES}/${SUBJECT}/anat/${file_compression}.nii.gz"
  echo
  echo "Looking for manual compression: ${FILE_COMPRESSION_MANUAL}"
  if [[ -e "${FILE_COMPRESSION_MANUAL}" ]]; then
    echo "Found! Using manual compression labels."
    rsync -avzh $FILE_COMPRESSION_MANUAL ${file_compression}.nii.gz
     
 	#sct_qc -i ${file}.nii.gz -s ${file_compression}.nii.gz  -qc "${PATH_QC}" -qc-subject "${SUBJECT}"
 	      
	# diameter_AP 
  	 sct_compute_compression -i ${file_t2_seg}.nii.gz -vertfile ${file_t2_labels}.nii.gz -l ${file_compression}.nii.gz -metric diameter_AP -normalize-hc 1 -o compression_metrics_AP.csv
   # cross-sectional area
    sct_compute_compression -i ${file_t2_seg}.nii.gz -vertfile ${file_t2_labels}.nii.gz  -l ${file_compression}.nii.gz -metric diameter_RL -normalize-hc 1 -o compression_metrics_RL.csv
   # diameter_RL
    sct_compute_compression -i ${file_t2_seg}.nii.gz -vertfile ${file_t2_labels}.nii.gz  -l ${file_compression}.nii.gz -metric area -normalize-hc 1 -o compression_metrics_csa.csv
   # eccentricity
    sct_compute_compression -i ${file_t2_seg}.nii.gz -vertfile ${file_t2_labels}.nii.gz  -l ${file_compression}.nii.gz -metric eccentricity -normalize-hc 1 -o compression_metrics_eccentricity.csv
   # solidity
    sct_compute_compression -i ${file_t2_seg}.nii.gz -vertfile ${file_t2_labels}.nii.gz  -l ${file_compression}.nii.gz -metric solidity -normalize-hc 1 -o compression_metrics_solidity.csv
   
 	
  else
    echo "Not found. Skipping the compression step."
  
  fi
} 

# Spinal cord compute compression
    # Note: For T2w images, we use sct_deepseg_sc with 2 kernel. Generally, it works better than sct_propseg and sct_deepseg_sc with 3d kernel.
        compression_if_does_not_exist ${file_t2w}  't2'  ${file_t2w}_label-compression-manual   'anat'
  
        cd ..
    else
        echo Skipping T2w
    fi
    
fi
 
##################################################################
# Process T2star
# This section will perform
#GM and WM segmentation
#Registration to PAM50 temaplate soace for normalized measures
#GM Morphometric measures
#Quantitative measure of GM and WM signal intensity
##################################################################
file_t2star=${file}_T2star
    # Check if T2star image exists
    if [[ -f ${file_t2star}.nii.gz ]];then
        # Create directory for T2star results
        mkdir -p ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/T2star
        mkdir -p ${PATH_RESULTS}/T2star
        cp ${file_t2star}.nii.gz ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/T2star
        cd T2star

        # Spinal cord segmentation
        segment_if_does_not_exist ${file_t2star} 't2s' 'deepseg' 'anat'
        file_t2star_seg="${file_t2star}_seg"

        # Spinal cord GM segmentation
        segment_gm_if_does_not_exist ${file_t2star}
        #sct_deepseg_gm -i ${file_t2star}.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
        file_t2star_gmseg="${file_t2star}_gmseg"
        
        # Get WM segmentation by subtracting SC cord segmentation with GM segmentation
        sct_maths -i ${file_t2star_seg}.nii.gz -sub ${file_t2star_gmseg}.nii.gz -o ${file_t2star}_wmseg.nii.gz
        file_t2star_wmseg="${file_t2star}_wmseg"

        # Register PAM50 T2s template to T2star using the WM segmentation
        sct_register_multimodal -i ${SCT_DIR}/data/PAM50/template/PAM50_t2s.nii.gz -iseg ${SCT_DIR}/data/PAM50/template/PAM50_wm.nii.gz -d ${file_t2star}.nii.gz -dseg ${file_t2star_wmseg}.nii.gz -param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=10:step=3,type=im,algo=syn,slicewise=1,iter=1,metric=CC -initwarp ../T2w/warp_template2anat.nii.gz -initwarpinv ../T2w/warp_anat2template.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
       
       # Registration of T2s from old code
        #sct_register_multimodal -i ${SCT_DIR}/data/PAM50/template/PAM50_t2s.nii.gz -iseg ${SCT_DIR}/data/PAM50/template/PAM50_wm.nii.gz -d ${file_t2star}.nii.gz -dseg ${file_t2star_wmseg}.nii.gz -param step=1,type=seg,algo=rigid:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=10:step=3,type=seg,algo=centermass,iter=10 -initwarp ../T2w/warp_template2anat.nii.gz -initwarpinv ../T2w/warp_anat2template.nii.gz  -qc ${PATH_QC} -qc-subject ${SUBJECT}
	
     	 # Warp template
        sct_warp_template -d ${file_t2star}.nii.gz -w warp_PAM50_t2s2${file_t2star}.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
        
        # Compute GM CSA (perlevel) between C2 and C8
        sct_process_segmentation -i ${file_t2star_gmseg}.nii.gz -vert 2:8 -angle-corr 0 -perlevel 1 -vertfile ./label/template/PAM50_levels.nii.gz -o ${PATH_RESULTS}/T2star/t2star_gm_csa.csv -append 1
       
        # Compute WM CSA (per level) between C2 and C8
		sct_process_segmentation -i ${file_t2star_wmseg}.nii.gz -vert 2:8 -angle-corr 0 -perlevel 1 -vertfile ./label/template/PAM50_levels.nii.gz -o ${PATH_RESULTS}/T2star/t2star_wm_csa.csv -append 1
       
		#Extract signal intensity and volumes from all level
        #Extract WM intensity and size at all levels
        sct_extract_metric -i ${file_t2star}.nii.gz -f ${file_t2star_wmseg}.nii.gz -z 2:8 -method bin -perslice 1 -append 1 -o ${PATH_RESULTS}/T2star/wm_in_t2star.csv #same as above worked correctly
		sct_extract_metric -i ${file_t2star}.nii.gz -f ${file_t2star_gmseg}.nii.gz -z 2:8 -method bin -perslice 1 -append 1 -o ${PATH_RESULTS}/T2star/gm_in_t2star.csv #only vert 7 worked for a DCM, same as above
		
			
		#Extract left ventral horn GM intensity and size at all levels
		sct_extract_metric -i ${file_t2star}.nii.gz -f ${file_t2star_gmseg}.nii.gz -z 2:8 -l 30 -method bin -perslice 1 -append 1 -o ${PATH_RESULTS}/T2star/LVgm_in_t2star28.csv 
		sct_extract_metric -i ${file_t2star}.nii.gz -f ${file_t2star_gmseg}.nii.gz -z 2:8 -l 31 -method bin -perslice 1 -append 1 -o ${PATH_RESULTS}/T2star/RVgm_in_t2star28.csv 
		sct_extract_metric -i ${file_t2star}.nii.gz -f ${file_t2star_gmseg}.nii.gz -z 2:8 -l 34 -method bin -perslice 1 -append 1 -o ${PATH_RESULTS}/T2star/LDgm_in_t2star28.csv 
		sct_extract_metric -i ${file_t2star}.nii.gz -f ${file_t2star_gmseg}.nii.gz -z 2:8 -l 35 -method bin -perslice 1 -append 1 -o ${PATH_RESULTS}/T2star/RDgm_in_t2star28.csv 
			
		
        cd ..
    else
        echo Skipping T2star
    fi   
fi	

    ###################################################################
    # MTS
    # This section will perform the following
    #Segmentation
    #Coregistration of MTon and Mtoff
    #Multimodal registration
   #MTR computation
   #Region and tract-based MTR extraction at vertebral levels
    ###################################################################
    # Add suffix corresponding to contrast
    file_MTS_t1w="${file}_acq-T1w_MTS"
    file_mton="${file}_acq-MTon_MTS"
    file_mtoff="${file}_acq-MToff_MTS"

    # Check if all MTS images exists
    if [[ -e "${file_MTS_t1w}.nii.gz" && -e "${file_mton}.nii.gz" && -e "${file_mtoff}.nii.gz" ]]; then

        # Create directory for MTS results
        mkdir -p ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/MTS
        # Copy files to processing folder
        cp ${file_MTS_t1w}.nii.gz ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/MTS
        #cp ${file_MTS_t1w}.json ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/MTS
        cp ${file_mton}.nii.gz ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/MTS
        #cp ${file_mton}.json ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/MTS
        cp ${file_mtoff}.nii.gz ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/MTS
        #cp ${file_mtoff}.json ${PATH_DATA_PROCESSED}/${SUBJECT}/anat/MTS
        cd MTS

        # Spinal cord segmentation of MT-on contrast
        segment_if_does_not_exist ${file_mton} 't2' 'deepseg' 'anat'
        file_mton_seg="${file_mton}_seg"

		# Create a close mask around the spinal cord for more accurate registration (i.e. does not account for surrounding tissue which could move independently from the cord)
		sct_create_mask -i ${file_mton}.nii.gz -p centerline,${file_mton_seg}.nii.gz -size 35mm -f cylinder -o ${file_mton}_mask.nii.gz
        file_mton_mask="${file_mton}_mask"
        
        # Register template->mton. The flag -initwarp ../T2w/warp_template2anat.nii.gz initializes the registration using the template->t2 transformation which was previously estimated
		sct_register_multimodal -i "${SCT_DIR}"/data/PAM50/template/PAM50_t2.nii.gz -iseg "${SCT_DIR}"/data/PAM50/template/PAM50_cord.nii.gz -d ${file_mton}.nii.gz -dseg ${file_mton_seg}.nii.gz -m ${file_mton}_mask.nii.gz -initwarp ../T2w/warp_template2anat.nii.gz -param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 -owarp warp_template2mt.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
		#sct_register_multimodal -i "${SCT_DIR}"/data/PAM50/template/PAM50_t2.nii.gz -iseg "${SCT_DIR}"/data/PAM50/template/PAM50_cord.nii.gz -d ${file_mton}.nii.gz -dseg ${file_mton_seg}.nii.gz -m ${file_mton}_mask.nii.gz -initwarp warp_template2anat.nii.gz -param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 -owarp warp_template2mt.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
		
		
		# Tips: Here we only use the segmentations (type=seg) to minimize the sensitivity of the registration procedure to image artifacts.
		# Tips: Step 1: algo=centermass to align source and destination segmentations, then Step 2: algo=bpslinesyn to adapt the shape of the cord to the mt modality (in case there are distortions between the t2 and the mt scan).

   		# Warp template
		sct_warp_template -d ${file_mton}.nii.gz -w warp_template2mt.nii.gz -a 1 -qc ${PATH_QC} -qc-subject ${SUBJECT}


		# Computing MTR using MT0/MT1 coregistration
		# ======================================================================================================================

		# Register mt0->mt1 using z-regularized slicewise translations (algo=slicereg)
		# Note: Segmentation and mask can be re-used from "MT registration" section
		sct_register_multimodal -i ${file_mtoff}.nii.gz -d ${file_mton}.nii.gz -dseg ${file_mton_seg}.nii.gz  -m ${file_mton}_mask.nii.gz -param step=1,type=im,algo=slicereg,metric=CC -x spline -qc ${PATH_QC} -qc-subject ${SUBJECT}
		sct_register_multimodal -i ${file_MTS_t1w}.nii.gz -d ${file_mton}.nii.gz -dseg ${file_mton_seg}.nii.gz -param step=1,type=im,algo=slicereg,metric=CC -m ${file_mton_mask}.nii.gz -x spline -qc ${PATH_QC} -qc-subject ${SUBJECT}

    
		# Compute MTR
		sct_compute_mtr -mt0 ${file_mtoff}_reg.nii.gz -mt1 ${file_mton}.nii.gz
		# Note: MTR is given in percentage.

	
        # MTR
        ############################################################
        # White matter 51 or 0:29 from all levels or across 2 levels
        ############################################################
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 2:3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_2_3.csv
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 3:4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_3_4.csv
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 4:5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_4_5.csv
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 5:6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_5_6.csv
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_2.csv
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_3.csv
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_4.csv
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_5.csv
        sct_extract_metric -i mtr.nii.gz -l 51 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_wm_6.csv
        
        
        ############################
        # Dorsal columns 53 or 0:3
        ############################
        # fasciculus gracilis column
        sct_extract_metric -i mtr.nii.gz -l 0 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3l_FG.csv
        sct_extract_metric -i mtr.nii.gz -l 0 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5l_FG.csv
        sct_extract_metric -i mtr.nii.gz -l 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3r_FG.csv
        sct_extract_metric -i mtr.nii.gz -l 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5r_FG.csv
        sct_extract_metric -i mtr.nii.gz -l 0,1 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_2_FG.csv
        sct_extract_metric -i mtr.nii.gz -l 0,1 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3_FG.csv
        sct_extract_metric -i mtr.nii.gz -l 0,1 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_4_FG.csv
        sct_extract_metric -i mtr.nii.gz -l 0,1 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5_FG.csv
        sct_extract_metric -i mtr.nii.gz -l 0,1 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_6_FG.csv
        
         
        # fasciculus cuneatus column
        sct_extract_metric -i mtr.nii.gz -l 2 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3l_FC.csv
        sct_extract_metric -i mtr.nii.gz -l 2 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5l_FC.csv
        sct_extract_metric -i mtr.nii.gz -l 3 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3r_FC.csv
        sct_extract_metric -i mtr.nii.gz -l 3 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5r_FC.csv
        sct_extract_metric -i mtr.nii.gz -l 2,3 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_2_FC.csv
        sct_extract_metric -i mtr.nii.gz -l 2,3 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3_FC.csv
        sct_extract_metric -i mtr.nii.gz -l 2,3 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_4_FC.csv
        sct_extract_metric -i mtr.nii.gz -l 2,3 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5_FC.csv
        sct_extract_metric -i mtr.nii.gz -l 2,3 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_6_FC.csv
        
         # dorsal column
	    sct_extract_metric -i mtr.nii.gz -l 0,2 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 0,2 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 1,3 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 1,3 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5r.csv
	    sct_extract_metric -i mtr.nii.gz -l 53 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_2.csv
        sct_extract_metric -i mtr.nii.gz -l 53 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_3.csv
        sct_extract_metric -i mtr.nii.gz -l 53 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_4.csv
        sct_extract_metric -i mtr.nii.gz -l 53 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5.csv
        sct_extract_metric -i mtr.nii.gz -l 53 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_dorsalcolumn_5.csv


        ##############################
        # Ventral columns 55 or 14:29
        ##############################
        sct_extract_metric -i mtr.nii.gz -l 14,16,18,20,22,24,26,28 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 14,16,18,20,22,24,26,28 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 15,17,19,21,23,25,27,29 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 15,17,19,21,23,25,27,29 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_5r.csv
        sct_extract_metric -i mtr.nii.gz -l 55 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_2.csv
        sct_extract_metric -i mtr.nii.gz -l 55 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_3.csv
        sct_extract_metric -i mtr.nii.gz -l 55 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_4.csv
        sct_extract_metric -i mtr.nii.gz -l 55 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_5.csv
        sct_extract_metric -i mtr.nii.gz -l 55 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_ventralcolumn_6.csv
        
        # Ventral corticospinal tract
        sct_extract_metric -i mtr.nii.gz -l 22 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 22 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 23 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 23 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_5r.csv
        sct_extract_metric -i mtr.nii.gz -l 22,23 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_2.csv
        sct_extract_metric -i mtr.nii.gz -l 22,23 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_3.csv
        sct_extract_metric -i mtr.nii.gz -l 22,23 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_4.csv
        sct_extract_metric -i mtr.nii.gz -l 22,23 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_5.csv
        sct_extract_metric -i mtr.nii.gz -l 22,23 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VCST_6.csv
        
        # Ventral reticulospinal tract
        sct_extract_metric -i mtr.nii.gz -l 16,20 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 16,20 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 17,21 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 17,21 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_5r.csv
        sct_extract_metric -i mtr.nii.gz -l 16,17,20,21 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_2.csv
        sct_extract_metric -i mtr.nii.gz -l 16,17,20,21 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_3.csv
        sct_extract_metric -i mtr.nii.gz -l 16,17,20,21 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_4.csv
        sct_extract_metric -i mtr.nii.gz -l 16,17,20,21 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_5.csv
        sct_extract_metric -i mtr.nii.gz -l 16,17,20,21 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_VRST_6.csv
       
      	#  spinal lemniscus tract
        sct_extract_metric -i mtr.nii.gz -l 12 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 12 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 13 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 13 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_5r.csv
        sct_extract_metric -i mtr.nii.gz -l 12,13 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_2.csv
        sct_extract_metric -i mtr.nii.gz -l 12,13 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_3.csv
        sct_extract_metric -i mtr.nii.gz -l 12,13 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_4.csv
        sct_extract_metric -i mtr.nii.gz -l 12,13 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_5.csv
        sct_extract_metric -i mtr.nii.gz -l 12,13 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_lemniscus_6.csv
       
        # spinoolivary tract
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 2:3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_2_3.csv
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 3:4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_3_4.csv
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 4:5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_4_5.csv
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 5:6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_5_6.csv
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_2.csv
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_3.csv
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_4.csv
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_5.csv
        sct_extract_metric -i mtr.nii.gz -l 14,15 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_SOT_6.csv
       
        #############################
        # Lateral columns 54 or 4:13
        ##############################
        sct_extract_metric -i mtr.nii.gz -l 4,6,8,10,12 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 4,6,8,10,12 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 5,7,9,11,13 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 5,7,9,11,13 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_5r.csv
        sct_extract_metric -i mtr.nii.gz -l 54 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_2.csv
        sct_extract_metric -i mtr.nii.gz -l 54 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_3.csv
        sct_extract_metric -i mtr.nii.gz -l 54 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_4.csv
        sct_extract_metric -i mtr.nii.gz -l 54 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_5.csv
        sct_extract_metric -i mtr.nii.gz -l 54 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_latcolumn_6.csv
        
        # Lat. corticospinal tract
        sct_extract_metric -i mtr.nii.gz -l 4 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 4 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 5 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 5 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_5r.csv
        sct_extract_metric -i mtr.nii.gz -l 4,5 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_2.csv
        sct_extract_metric -i mtr.nii.gz -l 4,5 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_3.csv
        sct_extract_metric -i mtr.nii.gz -l 4,5 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_4.csv
        sct_extract_metric -i mtr.nii.gz -l 4,5 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_5.csv
        sct_extract_metric -i mtr.nii.gz -l 4,5 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LCST_6.csv
        
        # Lateral reticulospinal tract
        sct_extract_metric -i mtr.nii.gz -l 10 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 10 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 11 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 11 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_5r.csv
        sct_extract_metric -i mtr.nii.gz -l 10,11 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_2.csv
        sct_extract_metric -i mtr.nii.gz -l 10,11 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_3.csv
        sct_extract_metric -i mtr.nii.gz -l 10,11 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_4.csv
        sct_extract_metric -i mtr.nii.gz -l 10,11 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_5.csv
        sct_extract_metric -i mtr.nii.gz -l 10,11 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_LRST_6.csv
       
      	#  rubrospinal tract
        sct_extract_metric -i mtr.nii.gz -l 8 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_3l.csv
        sct_extract_metric -i mtr.nii.gz -l 8 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_5l.csv
        sct_extract_metric -i mtr.nii.gz -l 9 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_3r.csv
        sct_extract_metric -i mtr.nii.gz -l 9 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_5r.csv
        sct_extract_metric -i mtr.nii.gz -l 8,9 -combine 1 -vert 2 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_2.csv
        sct_extract_metric -i mtr.nii.gz -l 8,9 -combine 1 -vert 3 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_3.csv
        sct_extract_metric -i mtr.nii.gz -l 8,9 -combine 1 -vert 4 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_4.csv
        sct_extract_metric -i mtr.nii.gz -l 8,9 -combine 1 -vert 5 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_5.csv
        sct_extract_metric -i mtr.nii.gz -l 8,9 -combine 1 -vert 6 -method map -f label/atlas -vertfile label/template/PAM50_levels.nii.gz -append 1 -o mtr_in_rubrospinal_6.csv
        
      	else
		echo Skipping MTS
	fi
