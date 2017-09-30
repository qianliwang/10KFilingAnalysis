=pod
sub searchKeyword{
    my (@keywordList) = @_;
	my $target = pop(@keywordList);
	my %result;
	my $num;
#	print("Total word count: ".countWord($target)."\n");
	foreach (@keywordList) {
		$num = 0;
		if($_ eq "CSR"){
	#	    print("Found CSR!!!\n");
			while ($target =~ m#\b$_\b#g)
			{
			   $num++;
			}
		}else{
			while ($target =~ m#\b$_[^\s]*\s#ig)
			{
			   $num++;
			}
		}
		$result{$_} = $num;
#	print("$result{$key}\n");
	}
	return %result;
}
=cut
sub searchKeyword{
    my (@keywordList) = @_;
	my $target = pop(@keywordList);
	my %result;
	my $num;
	my $negNum;
	my $tempValue;
#	print("Total word count: ".countWord($target)."\n");
	foreach (@keywordList) {
		$num = 0;
		$negNum = 0;
		$result{$_} = 0;
		$result{"neg_".$_} = 0;
		while ($target =~ m#((\w+\W+){3})$_#ig)
			{
#			print("$1 \n");
			$tempValue = $1;
			if($1 =~ m#\b(not|less|few|limited|no|mild)\b#){
				$negNum++;
				print("Found modifier: $tempValue \n");
				$result{"neg_".$_} = $negNum;
			}else{
				$num++;
				$result{$_} = $num;
			}
			   
			}
		
#	print("$result{$key}\n");
	}
	return %result;
}

sub convertHTMLtoTxt{
	my ($fileContent,$file) = @_;
	my $result;
	my $hs = HTML::Strip->new();

	$fileContent = cleanHTMLTags($fileContent);

	$clean_text = $hs->parse($fileContent);
	$hs->eof();

	$hs = undef;
	return $clean_text;
}

sub cleanHTMLTags{
	my ($fileContent) = @_;
	if($fileContent =~ s#<table\s+\w*align="center".*?</table>##ismg){
		print("Table Removed!\n");
	}
	if($fileContent =~ s#<p\s+\w*align="center".*?</p>##ismg){
		print("P Removed!\n");
	}
	for(my $type = 1;$type<=6;$type++){
		  my $headType = "h$type";
		  if($fileContent =~ s#<$headType.*?</$headType>##ismg){
		  print("$headType removed!\n");
		  }
	   }

	return $fileContent;
}

sub search_IncInfo_Keyword{

	my ($companyInfo,$keywords,$fileList,$logFile,$reportFile) = @_;

	my @fileList = @{$fileList};
	my @keywordList = @{$keywords};
	my @companyInfoList = @{$companyInfo};
	my @mergedSorted = (@companyInfoList,@keywordList,"TotalWordCount");

#	my $title = join(',',@mergedSorted);
	my $title = "";
	my $printTitle = 0;
	{
		my $ofh_report = select MYREPORT;
		$| = 1;
		select $ofh_report;
	}
	{
		my $ofh = select MYLOG;
		$| = 1;
		select $ofh;
	}
	if(not -e $logFile){
		$printTitle = 1;
	}
	open(MYREPORT, ">>:utf8" , $reportFile) or die "Could not open REPORT file: $reportFile!\n";
	open(MYLOG, ">>:utf8" , $logFile) or die "Could not open LOG file: $logFile!\n";
	
	my %companyInfo;
	my %keywordResult;
	my $result;
	my $documentBody;
	my $htmlBody;
	my $txtBody;
	my $tempFileName;
	foreach (@fileList){
		$tempFileName = basename($_);
		print("\n\n$tempFileName\n");
#			$fileContent = read_file($_);
#			$documentBody = getDocumentBody($fileContent);
		$documentBody = getDocumentBody($_);

		if(defined $documentBody){

			$htmlBody = getHTMLBody($documentBody);

			if(defined $htmlBody){
#				printFile($outputDir."html/",$tempFileName.".html",$htmlBody);
				$txtBody = convertHTMLtoTxt($htmlBody,$tempFileName);
			}else{
				$txtBody = $documentBody;
			}

			%companyInfo = getCompanyInfo(@companyInfoList,$documentBody);
			%keywordResult = searchKeyword(@keywordList,$txtBody);
			
			if($printTitle==1){
			
			    foreach my $key (sort keys %companyInfo){
					if($title eq ""){
						$title = $key;
					}else{
						$title = $title.",".$key;
					}
				}
				foreach my $key (sort keys %keywordResult){
					if($title eq ""){
						$title = $key;
					}else{
						$title = $title.",".$key;
					}					
				}
			
				print MYREPORT "$title\n";
				$printTitle = 0;
			}
	
			if(%companyInfo && %keywordResult){
#				checkHashContent(%companyInfo);
				$result = printHashContent(%companyInfo).",";
#				checkHashContent(%keywordResult);
				my $wordInFile = countWord($txtBody);
				$result = $result.printHashContent(%keywordResult).",".$wordInFile;

	#      print("$result\n");
				print MYREPORT "$result\n";
				my $logTime = localtime();
				print MYLOG "$logTime\t$tempFileName\n";
			}



		}else{
			print("Can't find the specific form in the file!\n");
		}

	}
	close MYREPORT;
	close MYLOG;

}

sub getKeyword{
	open my $info, $_[0] or die "Could not open $_[0]: $!\n";
	my @keywordList;

	if($^O =~ m#linux#i){
		while(<$info>){
#		chomp();
#		s/\s/_/g;
			my $line = $_;
			my $lastChar = chop();
			if($lastChar eq "\n"){
#		         print("$_\n");
				push(@keywordList,substr($_,0,-1));
			}else{
#                print("$_".$lastChar."\n");
				push(@keywordList,$line);
			}
		}
	}elsif($^O =~ m#mswin32#i){
		while(<$info>){
			chomp();
			push(@keywordList,$_);
		}
	}else{
		print("The running OS is neither Windows or Linux.\n");
	}

	close $info;
	return @keywordList;
}

sub countWord{
    my ($fileBlock) = @_;
	my $text = new Lingua::EN::Fathom;
    my $accumulate = 1;
	$text->analyse_block($fileBlock,$accumulate);
	my $num_words = $text->num_words;
	$text = undef;
	return $num_words;
}

sub getDocumentBody{
	my ($file) = @_;
	open my $info, $file or die "Could not open $file: $!";
    my $result= "";
	my $isTypeWanted = 0;
#	my $isFindEnd = 0;
	while( my $line = <$info>){

		$result = $result.$line;
		if($line =~ m#(^CONFORMED SUBMISSION TYPE:)\s*([^\n]+)\n#i){
			$isTypeWanted = 1;
			print("Found $2\n");
		}
		if($line =~ m#(^</DOCUMENT>)#i){
			if($isTypeWanted == 1){
				print("Found end\n");
				last;
			}else{
				$result = "";
			}
		}
	}
	close $info;
	return $result;
}

sub getHTMLBody{

	my ($txtContent) = @_;
   	my $result;
    if($txtContent =~ m#(^<html>.*?</html>)#ism){
#			   print($1."\n");
		$result = $1;
    }
	return $result;
}

sub getCompanyInfo{
    my (@companyInfos) = @_;
	my $txtContent = pop(@companyInfos);
	my %result;
#	if($txtContent =~ m#(^FILED AS OF DATE:[^>]*?>)#ism){
	if($txtContent =~ m#(^CONFORMED SUBMISSION TYPE:.*?<DOCUMENT>)#ism){
	    my $tempP = $1;
#		print($1."\n");

		foreach (@companyInfos) {
		   	if($tempP =~ m#$_:\s*([^\n]+)\n#im){
#				print("$key: ".$1."\n");
				my $tempValue = $1;
				$tempValue =~ s#,# #g;
				$result{$_} = $tempValue;
			}else{
				$result{$_} = " ";
			}
		}
	}
	return %result;

}
sub countPage
{
	my ($localTree) = @_;
	my @tempElements;
#	@tempElements = $localTree->look_down('_tag'=>'p','ALIGN'=>'center');
	@tempElements = $localTree->look_down('_tag'=>'p');
	my $tempP;
	my $currentPage = 0;
	for my $childElement (@tempElements){
			   $tempP = $childElement->as_text();
			   if($tempP =~ m#\b(\d+)\b#){
				  if($1 == $currentPage + 1){
#					print($1."\n");
					$currentPage = $1;
				  }

			   }
		 }
	return $currentPage;
}

sub loadData{

    my ($dir) = @_;
	opendir (DIR, $dir) or die("Could not open $dir");

	my $fileContent;
	my @fileList;
	while (my $file = readdir(DIR))
	{

		# Use a regular expression to ignore files beginning with a period
		next if ($file =~ m/^\./ || -d $file || not $file =~ m#\d.txt#s);

		push(@fileList,$dir.$file);
#		print("$file\n");
	}

	closedir(DIR);
	return @fileList;
}

sub printHashContent{
   my (%inputHash) = @_;
   my $result;
   foreach my $key (sort keys %inputHash){

#   print("$key:$inputHash{$key}\n");

       if($result eq ''){
		  $result = $inputHash{$key};

	   }else{
	      $result = $result.",".$inputHash{$key};
#		  print($result);
	   }

	}
	return $result;
}

sub checkHashContent{
   my (%inputHash) = @_;

   foreach my $key (sort keys %inputHash){
   print("$key:$inputHash{$key}\n");
	}
	return 0;
}

sub readInput{
   my ($inputArg) = @_;
   my @tempList;
   if (-f $inputArg) {
	push(@tempList,$inputArg);
   }

   if (-d $inputArg) {
	@tempList = loadData($inputArg);
   }
   return @tempList;
}

sub getFileList{

   my ($inputArg) = @_;
   my @tempList;
   if (-f $inputArg) {
	 open my $info, $inputArg or die "Could not open $inputArg: $!\n";
		while( my $line = <$info>)  {
			chomp($line);
			if($line ne ''){
				push(@tempList,$line);
			}
		}
	 close $info;
   }

   if (-d $inputArg) {
	@tempList = loadData($inputArg);
   }
   return @tempList;
}

sub askLog{
   my (@tempList) = @_;
   my $logPath = pop(@tempList);
   my $logContent = read_file($logPath);
   my @newList;
   my $tempFileName;
   foreach(@tempList){
      $tempFileName = basename($_);
      if(!($logContent =~ m#$tempFileName#ism) && ($tempFileName =~ m#[\d]+#)){
	    push(@newList,$_);
	  }
   }
   return @newList;
}

sub compareDiff{
	my ($largeArrayRef, $smallArrayRef) = @_;
    my @result = ();
	my %refHash;

	foreach my $key (@{$largeArrayRef}) {
        $refHash{$key} = 0;
    }
	foreach my $key (@{$smallArrayRef}) {
		if(exists $refHash{$key}){
			$refHash{$key} = 1;
		}else{
			print("$key doesn't Exist!!\n");
		}
    }
	foreach $key (sort keys %refHash){
		if($refHash{$key} == 0){
#			print("NT 10K: $key.\n");
			push(@result,$key);
		}
	}
	return @result;
}

sub compareHashArray{
	my ($hashRef, $smallArrayRef) = @_;
	my %hashVal = %$hashRef;
	my @result = ();

	foreach my $key (@{$smallArrayRef}) {
		if(exists $hashVal{$key}){
			$hashVal{$key} = "";
		}else{
			print("$key doesn't Exist!!\n");
		}
    }
	foreach $key (sort keys %hashVal){
		if($hashVal{$key} ne "" ){
#			print("NT 10K: $key.\n");
			push(@result,$hashVal{$key});
		}
	}
	return @result;

}

sub getAbsPath{
	my ($tempPath) = @_;
	$tempPath = abs_path($tempPath);
	$tempPath =~ s#/#\\#g;
	$tempPath = $tempPath."\\";
	return $tempPath;
}

1;
