# multiple_HMM_profiles_runner_SLURM
Built for University of Haifa HPC system (Hive) only and SLURM as an alternative for KoalaKofam (kofam_scan) that operates with KEGG HMM profiles. 
Runs HMM profiles against proteins (.faa files) using individual scores (optionally). Usesfull if you want to compare custom profiles. For KEGG annotations use Kofam.
The script monitors the number of jobs in SLURM system in aim not to overrload it with too many jobs. 

Once folders with .faa and .hmm files were defined, the script will ask for a table of score thresholds for each hmm profile (hmm_scores.txt):
"
Hydrogenase_Group_1.hmm	50
Hydrogenase_Group_2a.hmm	20
"

Summary table will be created in the end (Summary_table.txt):
"
file_number	file_name	hmm_profile_name	score_or_evalue_used
1	Chloroflexi_1.faa	Hydrogenase_Group_2a.hmm	20
1	Chloroflexi_1.faa	Hydrogenase_Group_1.hmm	50
2	Chloroflexi_2.faa	Hydrogenase_Group_2a.hmm	20
2	Chloroflexi_2.faa	Hydrogenase_Group_1.hmm	50
"
