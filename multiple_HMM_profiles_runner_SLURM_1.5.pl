## Created/modified by I Burgsdorf MARCH 2020.
## Usage: perl -w multiple_HMM_profiles_runner_SLURM.pl
## Run from SLURM-type system only!
## This script is writen to work with the HIVE HPC. You might correct the "system (...)" lines (87 and 112) if you are using different HPC system.
#===========================
use strict;
use warnings;
use File::Copy qw(move);
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path qw(make_path remove_tree); 
#=============================================================================================================================================================
# Create automatic output file with the report including used score or evalue, and file and hmm profiles numbers and names.
my $outTABLE = "Summary_table.txt";  
open(my $out, ">", $outTABLE) or die "cannot open $outTABLE";  # OUT
print $out "file_number\tfile_name\thmm_profile_name\tscore_or_evalue_used\n";
#=================================================================================================================================
my $counter_files = 0;
my $counter_hmms = 0;
my @table;
my $table;
my $evalue = 0;
my %hash;
my $hmm;
my $file;
my $answer;
my $input_file;
my $input_hmm;
my $Number_of_lines == 0;
my $Number_of_jobs == 0;

#--------------------------------------------
# Loading path to folder with .faa files. 
print "##############################################\n!!! HMMsearch should be added to your PATH/CONDA !!!\n##############################################\n";
#--------------------------------------------
# Loading path to folder with .faa files. 
print "Please provide path to directory with the .faa files (e.g. home/folder/folder_with_faa).\n If you are already in the working directory write \"./\"\n";
my $path1 = <STDIN>;
chomp ($path1);

opendir (DIR1, "$path1") || die "Couldn't open directory $path1!\n";
my @files = grep {/.faa/ and !/~/} readdir DIR1;
chomp @files;
closedir(DIR1);

my $files_number = @files;
print "$files_number .faa files were loaded.\n";
#--------------------------------------------
# Loading path to folder with .hmm files. 
print "Please provide path to directory with the .hmm files.\n If you are already in the working directory write \"./\"\n";
my $path2 = <STDIN>;
chomp ($path2);

opendir (DIR2, "$path2") || die "Couldn't open directory $path2!\n";
my @hmms = grep {/.hmm/ and !/~/} readdir DIR2;
chomp @hmms;
closedir(DIR2);

my $hmm_number = @hmms;
print "$hmm_number .hmm profiles were loaded.\n";
#--------------------------------------------
# Some hmm searches might require score threshold rather than e-value. In this case a table with hmm files names separated by /t with the score might be loaded.
print "Do you want to provide a table of score thresholds for each hmm profile?\n Please type \"yes\" or \"no\".\n";
$answer = <STDIN>;
chomp ($answer);
if ($answer eq "yes") {
	print "Put the table of the hmm profiles and scores to the folder of hmm profiles.\nUse \"hmm_scores.txt\" as a file name for the table\n";
	print "Please provide path to directory with the \"hmm_scores.txt\" table.\n If you are already in the working directory write \"./\"\n";
	my $path3 = <STDIN>;
	chomp ($path3);
	opendir (DIR3, "$path3") || die "Couldn't open directory $path3: $!!\n";     # Check if directory exists
	closedir(DIR3);
	my $in_table = "hmm_scores.txt"; 
	open (my $in, "<", "$path3/$in_table") or die "cannot open $path3/$in_table\n";     # IN
	# Load table with scores
	my @array = <$in>;
	chomp @array;
	close ($in);
	# Load hash table here from the file.
	# This walks through every line splitting on the '\t' sign and either adds an entry or appends to an existing entry in the hash table.
	%hash = map { split /\t/; } @array; 												
	# Loop that launching sbatch jobs with 20 cpus and 15 min limit for each profile-file.
	foreach $file (@files) {
		$counter_files++;
		$counter_hmms = @hmms;
		foreach $hmm (@hmms) {
			# Creating LINUX variabels identified to the PERL variables
			$input_file = "$path1/$file";
			$ENV{'input_file'} = "$input_file";
			$input_hmm = "$path2/$hmm";
			$ENV{'input_hmm'} = "$input_hmm";
			$ENV{'file'} = "$file";
			$ENV{'hmm'} = "$hmm";
			my $code = "$file\_$hmm";
			$ENV{'code'} = "$code";
			my $score = $hash{$hmm};
			$ENV{'score'} = "$score";
			system ('mkdir -p "${hmm%.hmm}"');
			system ('sbatch -J "${file%.faa}" --ntasks-per-node=20 -N 1 --partition=hive1d,hive7d --time=00:10:00 -e "${hmm%.hmm}/$code.er" -o "${hmm%.hmm}/$code.out" --wrap "hmmsearch --tblout ${hmm%.hmm}/${file}_${hmm}.hmmsearch.txt -T $score --cpu 20 $input_hmm $input_file"');
			# Printing out 
			print $out "$counter_files\t$file\t$hmm\t$hash{$hmm}\n";	
	    }
		system ('squeue -u iburgsdo | wc -l > temp_counter.txt');        # count number of jobs (number of lines - 1) 
		open (my $in_temp_counter, "<", "temp_counter.txt") or die "cannot open temp_counter.txt\n";     # IN
		$Number_of_lines =  <$in_temp_counter>;
		$Number_of_jobs = $Number_of_lines - 1;
		print "The number of running/pending jobs in SLURM is $Number_of_jobs.\n";
		sleep(10);                                                      # wait 10 seconds
		if ($Number_of_lines > 101) {									# If number of running/pending jobs is more than 100 
			until ($Number_of_lines < 11) {
				sleep(180);                                            # wait 3 minutes
				system ('squeue -u iburgsdo | wc -l >> temp_counter.txt');
				$Number_of_lines =  <$in_temp_counter>;
				$Number_of_jobs = $Number_of_lines - 1;
				print "The number of running/pending jobs in SLURM is $Number_of_jobs.\n";
			}
		}
		else { 
			next;
		}
	}
	print "$counter_files .faa files processed using $counter_hmms hmm profiles.\n";
}

elsif ($answer eq "no") {
	print "Please provide a E value threshold (e.g. 0.005)\n";
	$evalue = <STDIN>;
	chomp $evalue;	
	foreach $file (@files) {
		$counter_files++;
		$counter_hmms = @hmms;
		foreach $hmm (@hmms) {
			# Creating LINUX variabels identified to the PERL variables
			$input_file = "$path1/$file";
			$ENV{'input_file'} = "$input_file";
			$input_hmm = "$path2/$hmm";
			$ENV{'input_hmm'} = "$input_hmm";
			$ENV{'file'} = "$file";
			$ENV{'hmm'} = "$hmm";
			$ENV{'evalue'} = "$evalue";
			my $code = "$file\_$hmm";
			$ENV{'code'} = "$code";
			# Test
			# system ('sbatch -J "${file%.faa}" --ntasks-per-node=1 -N 1 --partition=steindler -e "$code.er" -o "$code.out" --wrap "echo $file"');
			system ('mkdir -p "${hmm%.hmm}"');
			system ('sbatch -J "${file%.faa}" --ntasks-per-node=20 -N 1 --partition=hive1d,hive7d --time=00:10:00 -e "${hmm%.hmm}/$code.er" -o "${hmm%.hmm}/$code.out" --wrap "hmmsearch --tblout ${hmm%.hmm}/${file}_${hmm}.hmmsearch.txt -E $evalue --cpu 20 $input_hmm $input_file"'); 
			# Printing out 
			print $out "$counter_files\t$file\t$hmm\t$evalue\n";
	    }
		system ('squeue -u iburgsdo | wc -l > temp_counter.txt');        # count number of jobs (number of lines - 1) 
		open (my $in_temp_counter, "<", "temp_counter.txt") or die "cannot open temp_counter.txt\n";     # IN
		$Number_of_lines =  <$in_temp_counter>;
		$Number_of_jobs = $Number_of_lines - 1;
		print "The number of running/pending jobs in SLURM is $Number_of_jobs.\n";
		sleep(10);                                                      # wait 10 seconds
		if ($Number_of_lines > 101) {									# If number of running/pending jobs is more than 100 
			until ($Number_of_lines < 11) {
				sleep(180);                                            # wait 3 minutes
				system ('squeue -u iburgsdo | wc -l >> temp_counter.txt');
				$Number_of_lines =  <$in_temp_counter>;
				$Number_of_jobs = $Number_of_lines - 1;
				print "The number of running/pending jobs in SLURM is $Number_of_jobs.\n";
			}
		}
		else { 
			next;
		}
	}
	print "$counter_files .faa files processed using $counter_hmms hmm profiles.\n";
}

else {  
	print "Please provide yes/no answer next time. Thanks!\n";
	system ('rm Summary_table.txt');
}
#--------------------------------------------

system ('rm temp_counter.txt');

close($out);
