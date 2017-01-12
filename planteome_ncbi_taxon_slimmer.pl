#!/usr/bin/perl

###############################################################
#  Justin Elser  (elserj@science.oregonstate.edu)             #
#		Parses the assoc files for any taxon ids              #
#		used in planteome assoc files.  Uses that to          #
#		generate small (slim) subset of the ncbi taxonomy     #
#		dat file.  From there, uses the owltools			  #
#		ncbi2owl.jar program to generate OWL file             #
#                                                             #
###############################################################


use strict;
use warnings;

# check for arguments and explain usage
if ($#ARGV !=4) {
	print "usage: planteome_ncbi_taxon_slimmer.pl taxonomy.dat_file assoc_file_directory obo_file_directory taxonomy_slim_file output_OWL_file\n";
	exit;
}

my $taxon_file = $ARGV[0];
my $assoc_dir = $ARGV[1];
my $obo_dir = $ARGV[2];
my $slim_file = $ARGV[3];
my $output_file = $ARGV[4];

my $ncbi_owltools_path = "/home/justin/owltools/OWLTools-NCBI/bin/ncbi2owl.jar";

# open the assoc files to be parsed

my @assoc_files = glob("$assoc_dir/*associations/*.assoc");

my %taxon_hash;
# taxon id 1 is required, I think
$taxon_hash{1} = 1;

# get the relevant taxon ids
foreach my $input_file (@assoc_files) {
	open(INFILE, "$input_file") || die "Error: file '$input_file' can not be opened\n";
	while(<INFILE>){
			my $line = $_;
			chomp $line;
			
			if($line =~ /axon:(\d+)/) {
					my $taxon = $1;
					if(!defined($taxon_hash{$taxon})){
							$taxon_hash{$taxon} = $taxon;
					}
			}
	}
	close(INFILE);
}

# open the obo files to be parsed to see if there are more taxon ids
my @obo_files = glob("$obo_dir/*.obo");

foreach my $input_file (@obo_files) {
	open(INFILE, "$input_file") || die "Error: file '$input_file' can not be opened\n";
	while(<INFILE>){
			my $line = $_;
			chomp $line;
			
			if($line =~ /Taxonomy_ID:(\d+)/) {
					my $taxon = $1;
					if(!defined($taxon_hash{$taxon})){
							$taxon_hash{$taxon} = $taxon;
					}
			}
	}
	close(INFILE);
}


# Attempt to get all parent ids as well and add them to the list
my $new_id = 1;
my $keep_section = 0;
my $counter = 0;
while($new_id == 1) {
		$new_id = 0;
		$counter++;
		open(TAXONFILE, "$taxon_file") || die "Error: file '$taxon_file' can not be opened\n";
		while (<TAXONFILE>){
				my $line = $_;
				chomp $line;
				
				if($line =~ /^ID\s+:\s(\d+)/) {
					if(defined($taxon_hash{$1})) {
							$keep_section = 1;
							next;
					}
				}
				
				if($keep_section == 1) {
						if($line =~ /^PARENT\sID\s+:\s(\d+)/) {
								if($1 != 0) {
										my $taxon = $1;
										if(!defined($taxon_hash{$taxon})) {
												$taxon_hash{$taxon} = $taxon;
												$new_id = 1;
												#print "Found a new id! $taxon\n";
										}
								}
						}
				}
				
				if($line =~ /^\/\//) {
				$keep_section = 0;
				}
		}
		close(TAXONFILE);
		#print "Counter = $counter\n";
		
}




# Read in the full taxon file from ncbi and output only the entries that have matching taxon ids
open(TAXONFILE, "$taxon_file") || die "Error: file '$taxon_file' can not be opened\n";
open(TAXONSLIM, ">$slim_file") || die "Error: file '$slim_file' can not be opened for writing\n";
$keep_section = 0;
while(<TAXONFILE>){
		my $line = $_;
		chomp $line;
		
		if($line =~ /^ID\s+:\s(\d+)/) {
				if(defined($taxon_hash{$1})) {
						print TAXONSLIM "$line\n";
						$keep_section = 1;
						next;
				}
		}
		
		if($keep_section == 1) {
				print TAXONSLIM "$line\n";
		}
		
		if($line =~ /^\/\//) {
				$keep_section = 0;
		}
}
close(TAXONFILE);
close(TAXONSLIM);
				
						
system("java -Xmx6G -jar $ncbi_owltools_path $slim_file $output_file");

# Print out a list of all taxon ids

open(IDFILE, ">taxon_id.lst");
foreach my $key (sort {$a<=>$b} keys %taxon_hash) {
		print IDFILE "$key\n";
}

