#!/usr/bin/perl
use strict;
use warnings;
use File::Path;
use File::Slurp;
use File::Basename;
use HTML::Strip;
use HTML::TreeBuilder;
use feature qw(switch);
use Lingua::EN::Fathom;
use Cwd 'abs_path';
require 'global_function.pl';

# The 4th script supposed to be executed. With downloaded filings, like 10K, and the txt files containing the wantted 
# information, like the commpany info and keywords. The script extracts the company information and counts the occurrences 
# of keywords, then saved the data in a given format for later analysis. 

if((scalar @ARGV) < 2){

	die "Please provide at least 2 parameters, the first one is the directory where filings are saved, the last one is the directory where the report will be saved.\nThank you.\n";
}

#By default, the keywords are stored line by line in the "keywords.txt", the company information items are stored line by line in the "companyInfo.txt". The program will load these two files before everything. If these two files are missing, the program will stop.  
my $keywordFile = "./configure/keywords.txt";
my $companyInfoFile = "./configure/companyInfo.txt";
my @keywordList;
my @companyInfoList;
if(-e $keywordFile){
	@keywordList = getKeyword($keywordFile);
	@keywordList = sort(@keywordList);
}else{
	die "Can't find the file contains keyword list. P.S: The file must be saved in '.\\configure\\' and named as 'keywords.txt'.\n";
}

if(-e $companyInfoFile){
	@companyInfoList = getKeyword($companyInfoFile); 
	@companyInfoList = sort(@companyInfoList);
}else{
	die "Can't find the file contains company information. P.S: The file must be saved in '.\\configure\\' and named as 'companyInfo.txt'.\n";
}

my $outputDir = pop(@ARGV);
my $inputPath;
my $logFile;
my $logContent;
my $reportFile;
my @fileListinDir;

eval{mkpath($outputDir)};
if (!(-d $outputDir)) {
	die "Please provide a valid output directory.\n";
}

my $tempPath = getAbsPath($outputDir);
print("\nThe report will be saved in $tempPath \nAnalyzing will start in 3 seconds.\n\n");
sleep 3;

while((scalar @ARGV) != 0){
	$inputPath = shift(@ARGV);
	if (-e $inputPath && -d $inputPath) {
		@fileListinDir = getFileList($inputPath);
		print((scalar @fileListinDir)." files in $inputPath \n");

		my $tempYear = $inputPath;
		chop($tempYear);
		if($tempYear =~ m#([\d]+)$#){
#		print("$1\n");
		}else{
			print("Didn't find the parent directory name!\n");
		}
		$logFile = $inputPath."log_analyze.txt";
		$reportFile = $outputDir."$1_report.txt";
		
		if(-e $logFile){
			@fileListinDir = askLog(@fileListinDir,$logFile);	
		}
		print((scalar @fileListinDir)." files are going to be analyzed.\n");

		search_IncInfo_Keyword(\@companyInfoList,\@keywordList,\@fileListinDir,$logFile,$reportFile);
#		search_IncInfo(@fileListinDir,$outputDir);
	}else{
		die "Wrong argument, please give a directory for analyzing.\n";
	}  
}
