#!/usr/bin/perl
# Program to download index files from EDGAR
# Copied almost verbatim from the LWP::UserAgent documentation
# Credit given to Diego Garcia, 2012, UNC at Chapel Hill
use strict;
use warnings;
use Cwd 'abs_path';
use File::Path;
use LWP::UserAgent;
require 'global_function.pl';

my $argvLength = scalar @ARGV;
my $startYear = 0;
my $endYear = 0;
my $outputDir = "";

if($argvLength == 2){
	$startYear = $ARGV[0];
	$endYear = $startYear;
	eval{mkpath($ARGV[1])};
	if(-d $ARGV[1]){
		$outputDir = $ARGV[1];	
	}else{
		die "Not valid output directory!\n";
	}
	
}elsif($argvLength == 3){
	$startYear = $ARGV[0];
	$endYear = $ARGV[1];
	eval{mkpath($ARGV[2])};
	if(-d $ARGV[2]){
		$outputDir = $ARGV[2];	
	}else{
		die "Not valid output directory!\n";
	}
}else{
	die "Please provide at least 2 parameters, the first one is the year, the second one is the directory where the full index will be saved. \nYou can also provide 3 parameters, the first one is the start year, the second one is the end year, and the third one is the directory where the full index will be saved.\nThank you.\n";
}

### make sure the output directory exists ####
   my $tempPath = getAbsPath($outputDir);
   print("Index file is saved in $tempPath \n");
   downloadByYear($startYear,$endYear,$outputDir);

exit 0;

sub downloadByYear
{
    my ($startYear,$endYear,$outputDir) = @_;
	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);
    $ua->env_proxy;
	my $quarter;
	my $filegrag;
	my $response;
	my $filename; 
	my $year;
	
    for($year=$startYear; $year<=$endYear; $year=$year+1){
        $filename = $outputDir.$year."_full_index.txt";
		open(MYOUTFILE, ">:utf8" , $filename) or die "Could not open $filename!\n";;
		for(my $i=1; $i<5; $i=$i+1){
            $quarter = "QTR" . $i;
			$filegrag = "ftp://ftp.sec.gov/edgar/full-index/" . $year . "/" . $quarter . "/form.gz";
			
			$response = $ua->get($filegrag);

			if ($response->is_success) {
			    print "$filegrag is downloaded.\n";
				print MYOUTFILE $response->decoded_content; # or whatever
			}
			else {
	            print $response->status_line."\n";
			}
	        $ua->delete($filegrag);
		}
		close(MYOUTFILE);
	}
}

