#!/usr/bin/perl -w

# COMP[29]041 Assignment 1 - 17S2
# Author: Mohamed Daniel Al Mouiee z5114185

open F, '<',"$ARGV[0]" or die;
$progName = $ARGV[0];
$progName =~ s/\.py/\.pl/;
@perlLines =();
while($line = <F>) {
	chomp $line;
	# Checks for empty lines in .py file
	if($line eq "") {
		push(@perlLines,"\n");
		next;
	}
	#Subset 0
	if($line =~ /\/python[23]/) {
		$line =~ s/\/python[23]/\/perl -w/;
	} else{
		if($line =~ /print\(.*\)/) {
			$line =~ s/\(|\)//g;
		}
		#Subset 1: deals with Variables, Constants and Maths operations										
		if($line =~ /^[\w]* *= *[\w]*/) {
			print"went in\n";
			($first, $second) = $line =~ /^([\w]*) *= *([\w]*)/;
			print"$second\n";
			$line =~ s/($1)/\$$first /;
			$line =~ s/= *[A-Za-z]*/= \$$second/;
			#Maps equations with +
			@matchesAdd = $line =~ /\+ *[A-Za-z]/g;
			foreach $matchAdd (@matchesAdd) {
				$matchAdd =~ s/\+ *//;
				$line =~ s/\+ *$matchAdd/\+ \$$matchAdd/m;
			}
			#Maps equations with -
			@matchesSub = $line =~ /\- *[A-Za-z]/g;
			foreach $matchSub (@matchesSub) {
				$matchSub =~ s/\- *//;
				$line =~ s/\- *$matchSub/\-\$$matchSub/m;
			}
			#Maps equations with /
			@matchesDiv = $line =~ /\/ *[A-Za-z]/g;
			foreach $matchDiv (@matchesDiv) {
				$matchDiv =~ s/\/ *//;
				$line =~ s/\/ *$matchDiv/\/\$$matchDiv/m;
			}
			#Maps equations with **/^
			@matchesTimes = $line =~ /\* *[A-Za-z]/g;
			foreach $matchTimes (@matchesTimes) {
				$matchTimes =~ s/\* *//;
				$line =~ s/\* *$matchTimes/\*\$$matchTimes/m;
			}
			@matchesPowers = $line =~ /\*\* *[A-Za-z]/g;
			foreach $matchPowers (@matchesPowers) {
				$matchPowers =~ s/\*\* *//;
				$line =~ s/\*\* *$matchPowers/\*\*\$$matchPowers/m;
			}
		}
		$line .= ";";
	}
	push(@perlLines,$line);
}
close F;
open my $F, '>', "$progName" or die;
foreach $Line (@perlLines) {
	print $F "$Line" if $Line ne "\n";
	print $F "\n";
}
close $F;