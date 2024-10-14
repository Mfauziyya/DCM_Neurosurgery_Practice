#!/bin/sh
# Batch run All tracts
#hc and CSM
# Created by Fauziyya Muhammad.

		
data_path="/path/to/your/working directory"  # Adjust this path to the directory containing your fMTR csv results


subjects=#list subjects 
# Define the output CSV file
output_csv5="${data_path}/mtr_values_batch.csv"

# Write the header to the output CSV(mtr_values_batch.csv)
echo "subject,mtr_in_wm_3,mtr_in_wm_5,mtr_in_dorsalcolumn_3,mtr_in_dorsalcolumn_5,mtr_in_dorsalcolumn_3l,mtr_in_dorsalcolumn_5l,mtr_in_dorsalcolumn_3r,mtr_in_dorsalcolumn_5r,mtr_in_dorsalcolumn_3_FG,mtr_in_dorsalcolumn_5_FG,mtr_in_dorsalcolumn_3l_FG,mtr_in_dorsalcolumn_5l_FG,mtr_in_dorsalcolumn_3r_FG,mtr_in_dorsalcolumn_5r_FG,mtr_in_dorsalcolumn_3_FC,mtr_in_dorsalcolumn_5_FC,mtr_in_dorsalcolumn_3l_FC,mtr_in_dorsalcolumn_5l_FC,mtr_in_dorsalcolumn_3r_FC,mtr_in_dorsalcolumn_5r_FC,mtr_in_ventralcolumn_3,mtr_in_ventralcolumn_5,mtr_in_ventralcolumn_3l,mtr_in_ventralcolumn_5l,mtr_in_ventralcolumn_3r,mtr_in_ventralcolumn_5r,mtr_in_VCST_3,mtr_in_VCST_5,mtr_in_VCST_3l,mtr_in_VCST_5l,mtr_in_VCST_3r,mtr_in_VCST_5r,mtr_in_VRST_3,mtr_in_VRST_5,mtr_in_VRST_3l,mtr_in_VRST_5l,mtr_in_VRST_3r,mtr_in_VRST_5r,mtr_in_lemniscus_3,mtr_in_lemniscus_5,mtr_in_lemniscus_3l,mtr_in_lemniscus_5l,mtr_in_lemniscus_3r,mtr_in_lemniscus_5r,mtr_in_SOT_3,mtr_in_SOT_5,mtr_in_latcolumn_3,mtr_in_latcolumn_5,mtr_in_latcolumn_3l,mtr_in_latcolumn_5l,mtr_in_latcolumn_3r,mtr_in_latcolumn_5r,mtr_in_LRST_3,mtr_in_LRST_5,mtr_in_LRST_3l,mtr_in_LRST_5l,mtr_in_LRST_3r,mtr_in_LRST_5r,mtr_in_rubrospinal_3,mtr_in_rubrospinal_5,mtr_in_rubrospinal_3l,mtr_in_rubrospinal_5l,mtr_in_rubrospinal_3r,mtr_in_rubrospinal_5r,mtr_in_LCST_3,mtr_in_LCST_5,mtr_in_LCST_3l,mtr_in_LCST_5l,mtr_in_LCST_5r,mtr_in_LCST_5r" > "$output_csv5"


# Loop over each subject
for subject in "${subjects[@]}"; do
    # Change to your analysis folder and to the subject's directory
    subject_dir="path/to/your/batch_folder/data_processed/${subject}/ses-spinalcord/anat/MTS"
    #example: subject_dir="${data_path}/sc_analysis_mtr_sample/data_processed/${subject}/ses-spinalcord/anat/MTS"
    cd "$subject_dir" || continue

    # Initialize an array to hold all the metric values for the subject
    metric_values=()

    # Extract the MAP() value for each metric and add to the array
    metric_values+=("$(tail -n +2 mtr_in_wm_3.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_wm_5.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3l.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5l.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3r.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5r.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3_FG.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5_FG.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3l_FG.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5l_FG.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3r_FG.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5r_FG.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3_FC.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5_FC.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3l_FC.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5l_FC.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_3r_FC.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_dorsalcolumn_5r_FC.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_ventralcolumn_3.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_ventralcolumn_5.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_ventralcolumn_3l.csv | head -n 1 | cut -d ',' -f16)")
    metric_values+=("$(tail -n +2 mtr_in_ventralcolumn_5l.csv | head -n 1 | cut -d ',' -f16)")
    metric_values+=("$(tail -n +2 mtr_in_ventralcolumn_3r.csv | head -n 1 | cut -d ',' -f16)")
    metric_values+=("$(tail -n +2 mtr_in_ventralcolumn_5r.csv | head -n 1 | cut -d ',' -f16)")
    metric_values+=("$(tail -n +2 mtr_in_VCST_3.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_VCST_5.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_VCST_3l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_VCST_5l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_VCST_3r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_VCST_5r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_VRST_3.csv | head -n 1 | cut -d ',' -f12)")
    metric_values+=("$(tail -n +2 mtr_in_VRST_5.csv | head -n 1 | cut -d ',' -f12)")
    metric_values+=("$(tail -n +2 mtr_in_VRST_3l.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_VRST_5l.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_VRST_3r.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_VRST_5r.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_lemniscus_3.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_lemniscus_5.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_lemniscus_3l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_lemniscus_5l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_lemniscus_3r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_lemniscus_5r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_SOT_3.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_SOT_5.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_latcolumn_3.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_latcolumn_5.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_latcolumn_3l.csv | head -n 1 | cut -d ',' -f13)")
    metric_values+=("$(tail -n +2 mtr_in_latcolumn_5l.csv | head -n 1 | cut -d ',' -f13)")
    metric_values+=("$(tail -n +2 mtr_in_latcolumn_3r.csv | head -n 1 | cut -d ',' -f13)")
    metric_values+=("$(tail -n +2 mtr_in_latcolumn_5r.csv | head -n 1 | cut -d ',' -f13)")
    metric_values+=("$(tail -n +2 mtr_in_LRST_3.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_LRST_5.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_LRST_3l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_LRST_5l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_LRST_3r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_LRST_5r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_rubrospinal_3.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_rubrospinal_5.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_rubrospinal_3l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_rubrospinal_5l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_rubrospinal_3r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_rubrospinal_5r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_LCST_3.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_LCST_5.csv | head -n 1 | cut -d ',' -f10)")
    metric_values+=("$(tail -n +2 mtr_in_LCST_3l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_LCST_5l.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_LCST_3r.csv | head -n 1 | cut -d ',' -f9)")
    metric_values+=("$(tail -n +2 mtr_in_LCST_5r.csv | head -n 1 | cut -d ',' -f9)")
    

    # Write the subject and all metric values as a single line to the output CSV
    echo "${subject},$(IFS=,; echo "${metric_values[*]}")" >> "$output_csv5"
done


 