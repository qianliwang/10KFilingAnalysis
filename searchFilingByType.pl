#!/usr/bin/perl
use strict;
use warnings;
use File::Path;
use Cwd 'abs_path';
require 'global_function.pl';

# The 2nd supposed to be executed script.Extract the certain filings from the previously downloaded index file, like 10K. 
# The extracted corresponding links are saved in another txt file.

if((scalar @ARGV) < 3){
	die "Please provide at least 3 parameters, the first one is the full index File, the second-to-last one is the filing type, like '10-K', the last one is the directory where the filing index will be saved. \nThank you.\n"
}

my $outputDir = pop(@ARGV);
my $type = pop(@ARGV);

if (not defined $type || not defined $outputDir) {
  die "Please indicate the form type, like '10-K', and the output directory.\n";
}
my $outputPath = $outputDir."$type\\";
eval{mkpath($outputPath)};

my $tempPath = getAbsPath($outputPath);
print("$type index file is saved in $tempPath \n");

foreach my $arg (@ARGV) {
	foreach (glob $arg) {
		if(not defined $_ || not -e $_ || not -f $_){
			die "The file you want to search into does not exit!\n";
		}else{
			searchForm($_,$type,$outputPath);
#			print("search index file $_ \n");	
		}
	}
}
exit 0;


sub searchForm{

    my ($indexFile,$type,$outputPath) = @_;
	
	if($indexFile =~ m#(\d{4})_#){
		open my $info, $indexFile or die "Could not open $indexFile: $!\n";
		my $filePath = "$outputPath$1\_$type\_index.txt";
	#	my $filePreFix = "ftp://ftp.sec.gov/"; 
		my $counting = 0;
		open(MYOUTFILE, ">:utf8" , $filePath) or die "Could not open $filePath!\n";
		while( my $line = <$info>)  {

			if($line =~ /^\b$type\s/){
	#		    print($line."\n");
			   $line =~ /(\d{1,})\s+(\d{4}-\d{2}-\d{2})\s+(edgar.*txt)/;
	#		   print("CIK: ".$1."\n");
	#		   print("File Date: ".$2."\n");
	#		   print("Link : ".$filePreFix.$3."\n");
	#		   print MYOUTFILE $filePreFix.$3."\n";
			   print MYOUTFILE $3."\n";
			   $counting++;
			}	
	#		print $line;    
	#		last if $. == 2;
		}
		print("Found $counting $type filings.\n");
		close MYOUTFILE;
		close $info;
	}
	else{
		print("Can't find the year in the name of $indexFile !\n");
	}
	
	
	
}


