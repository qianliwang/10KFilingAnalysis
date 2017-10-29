#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use File::Path;
use File::Basename;
use File::Slurp;
use Cwd 'abs_path';
require 'global_function.pl';

# The 3rd script supposed to be executed. Once the type of filing is determined, the filings are downloaded agin from SEC 
# ftp server. Since the size of data could be up to GBs, we use a log file to record all the downloaded filings, in case
# the downloading process is interrupted.


if((scalar @ARGV) < 2){

	die "Please provide at least 2 parameters, the first one is the index file, the last one is the directory where filings will be saved.\nThank you.\n";
}

my $outputDir = pop(@ARGV);
my $inputPath;
my $logFile;
my $logContent;
my @downloadListInFile;
eval{mkpath($outputDir)};
if (!(-d $outputDir)) {
	die "Please provide a valid output directory.\n";
}

my $tempPath = getAbsPath($outputDir);
print("\nThe filings will be saved in $tempPath \n\n");


foreach my $arg (@ARGV) {
	foreach (glob $arg) {
		$inputPath = $_;
		if (-e $inputPath && -f $inputPath) {
			@downloadListInFile = getFileList($inputPath);
#			my $fileAmountInFile = (scalar @downloadListInFile);
#			my @backUpList = @downloadListInFile;
#			print("$fileAmountInFile files in $inputPath.\n");

			if($inputPath =~ m#(\d{4})_([^_]+)_#){
				$outputDir = $outputDir."$2\\$1\\";
				eval{mkpath($outputDir)};
				my @downloadedListInDir = getFileList($outputDir);
				
				my @downloadListNames;
				my @downloadedFileNames;
				my $tempName = "";
				my %downloadHashList;
				my $tempName2 = "";
				foreach (@downloadListInFile){
					$tempName = basename($_);
				#	print("$tempName\n");
					if($tempName =~ m#\d.txt#s){
						push(@downloadListNames,"$tempName");
						$tempName2 = "$tempName"; 
						$_ = m#(\d+\/.*?\.txt)#s;
	#					print("$1\n");

						if(not exists $downloadHashList{$tempName2}){
							$downloadHashList{$tempName2} = $1;
						}else{
	#						print("$1\n");
						}
						
					}
					
				}
				my $size = keys %downloadHashList;
				print("$size files in total.\n");
				
				foreach (@downloadedListInDir){
					$tempName = basename($_);
				#	print("$tempName\n");
					if($tempName =~ m#\d.txt#s){
						push(@downloadedFileNames,"$tempName");
					}
					
				}
				
	#			print((scalar @downloadedFileNames));
	#			print("\n");
				
				my @needToDownload = compareHashArray(\%downloadHashList,\@downloadedFileNames);
				
				print((scalar @needToDownload)." files are going to be downloaded.\n");
				downloadFile(@needToDownload,$outputDir);
			}else{
				die "Please provide a valid index file.\n"
			}
			
		}else{
			die "The index file doesn't exist!\n";
		}  
	}
}

exit 0;

sub downloadFile{
   my (@fileList) = @_;
   my $outputDir = pop(@fileList);
   my $ua = LWP::UserAgent->new;
   $ua->timeout(10);
   $ua->env_proxy;
   my $filePath;
   my $response;
   my $tempFile;
   my $logFile = $outputDir."log_download.txt";
   
   { my $ofh = select MYLOG;
	  $| = 1;
	  select $ofh;
   }
	
   my $logTime;
   open(MYLOG, ">>" . $logFile) or die "Could not open LOG file: $logFile!\n";
   my $tempFileName;
   foreach (@fileList) {
   
	$filePath = "ftp://ftp.sec.gov/edgar/data/$_";
	$response = $ua->get($filePath);
	$logTime = localtime();
	if ($response->is_success){
		print "$filePath is downloaded.\n";
		
		
		$tempFile = $outputDir.basename($_);
		open(MYOUTFILE, ">:utf8" , $tempFile) or die "Could not open $tempFile!\n";
		if(print MYOUTFILE $response->decoded_content){ # or whatever
			print MYLOG "$logTime\t$_\n";
		}else{
			print "$_ failed to save on disk.\n";
		} 
		close MYOUTFILE;
	}
	else {
#			die $response->status_line;
		print $response->status_line."\n";
	}
	$ua->delete($filePath);
  }
  close MYLOG;
}
