#!/bin/sh
# Batch run All tracts
#hc and CSM
# Created by Fauziyya Muhammad.

		
data_path="/Users/${working directory}"  # Adjust this path to the directory containing your files


subjects=#list subjects 
# Define the output CSV file
output_csv5="${data_path}/mtr_values_batch.csv"

# Write the header to the output CSV
#echo "subject,mtr_in_wm_2_3,mtr_in_wm_3_4,mtr_in_wm_4_5,mtr_in_wm_5_6,mtr_in_dorsalcolumn_2_3_right,mtr_in_dorsalcolumn_3_4_right,mtr_in_dorsalcolumn_4_5_right,mtr_in_dorsalcolumn_5_6_right,mtr_in_dorsalcolumn_2_3_left,mtr_in_dorsalcolumn_3_4_left,mtr_in_dorsalcolumn_4_5_left,mtr_in_dorsalcolumn_5_6_left,mtr_in_dorsalcolumn_2_3,mtr_in_dorsalcolumn_3_4,mtr_in_dorsalcolumn_4_5,mtr_in_dorsalcolumn_5_6,mtr_in_ventralcolumn_2_3,mtr_in_ventralcolumn_3_4,mtr_in_ventralcolumn_4_5,mtr_in_ventralcolumn_5_6,mtr_in_VCST_2_3,mtr_in_VCST_3_4,mtr_in_VCST_4_5,mtr_in_VCST_5_6,mtr_in_VRST_2_3,mtr_in_VRST_3_4,mtr_in_VRST_4_5,mtr_in_VRST_5_6,mtr_in_lemniscus_2_3,mtr_in_lemniscus_3_4,mtr_in_lemniscus_4_5,mtr_in_lemniscus_5_6,mtr_in_SOT_2_3,mtr_in_SOT_3_4,mtr_in_SOT_4_5,mtr_in_SOT_5_6,mtr_in_latcolumn_2_3,mtr_in_latcolumn_3_4,mtr_in_latcolumn_4_5,mtr_in_latcolumn_5_6,mtr_in_LRST_2_3,mtr_in_LRST_3_4,mtr_in_LRST_4_5,mtr_in_LRST_5_6,mtr_in_rubrospinal_2_3,mtr_in_rubrospinal_3_4,mtr_in_rubrospinal_4_5,mtr_in_rubrospinal_5_6,mtr_in_LCST_2_3,mtr_in_LCST_3_4,mtr_in_LCST_4_5,mtr_in_LCST_5_6" > "$output_csv5"
echo "subject,mtr_in_wm_3,mtr_in_wm_5,mtr_in_dorsalcolumn_3,mtr_in_dorsalcolumn_5,mtr_in_dorsalcolumn_3l,mtr_in_dorsalcolumn_5l,mtr_in_dorsalcolumn_3r,mtr_in_dorsalcolumn_5r,mtr_in_dorsalcolumn_3_FG,mtr_in_dorsalcolumn_5_FG,mtr_in_dorsalcolumn_3l_FG,mtr_in_dorsalcolumn_5l_FG,mtr_in_dorsalcolumn_3r_FG,mtr_in_dorsalcolumn_5r_FG,mtr_in_dorsalcolumn_3_FC,mtr_in_dorsalcolumn_5_FC,mtr_in_dorsalcolumn_3l_FC,mtr_in_dorsalcolumn_5l_FC,mtr_in_dorsalcolumn_3r_FC,mtr_in_dorsalcolumn_5r_FC,mtr_in_ventralcolumn_3,mtr_in_ventralcolumn_5,mtr_in_ventralcolumn_3l,mtr_in_ventralcolumn_5l,mtr_in_ventralcolumn_3r,mtr_in_ventralcolumn_5r,mtr_in_VCST_3,mtr_in_VCST_5,mtr_in_VCST_3l,mtr_in_VCST_5l,mtr_in_VCST_3r,mtr_in_VCST_5r,mtr_in_VRST_3,mtr_in_VRST_5,mtr_in_VRST_3l,mtr_in_VRST_5l,mtr_in_VRST_3r,mtr_in_VRST_5r,mtr_in_lemniscus_3,mtr_in_lemniscus_5,mtr_in_lemniscus_3l,mtr_in_lemniscus_5l,mtr_in_lemniscus_3r,mtr_in_lemniscus_5r,mtr_in_SOT_3,mtr_in_SOT_5,mtr_in_latcolumn_3,mtr_in_latcolumn_5,mtr_in_latcolumn_3l,mtr_in_latcolumn_5l,mtr_in_latcolumn_3r,mtr_in_latcolumn_5r,mtr_in_LRST_3,mtr_in_LRST_5,mtr_in_LRST_3l,mtr_in_LRST_5l,mtr_in_LRST_3r,mtr_in_LRST_5r,mtr_in_rubrospinal_3,mtr_in_rubrospinal_5,mtr_in_rubrospinal_3l,mtr_in_rubrospinal_5l,mtr_in_rubrospinal_3r,mtr_in_rubrospinal_5r,mtr_in_LCST_3,mtr_in_LCST_5,mtr_in_LCST_3l,mtr_in_LCST_5l,mtr_in_LCST_5r,mtr_in_LCST_5r" > "$output_csv5"



# Loop over each subject
for subject in "${subjects[@]}"; do
    # Change to your analysis folder and to the subject's directory
    subject_dir="${data_path}/${analysis_folder}/data_processed/${subject}/ses-spinalcord/anat/MTS"
    #subject_dir="${data_path}/sc_analysis_mtr_sample/data_processed/${subject}/ses-spinalcord/anat/MTS"
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


 