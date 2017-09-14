#!/usr/bin/perl -w

# COMP[29]041 Assignment 1 - 17S2
# Author: Mohamed Daniel Al Mouiee z5114185


sub variableMapper {
    my ($Line) = @_;
    ($first, $second) = $Line =~ /^([\w]*) *= *\(*([\w]*\)*)/;
	$Line =~ s/($1)/\$$first /;
	# If there are parentheses (at most 1) that wrap the variables
	$Line =~ s/= *[A-Za-z]+[\w]*/= \$$second/ if $Line =~ /= *([\w]*)/;;
	$Line =~ s/= *\([A-Za-z]+[\w]*\)/= \(\$$second/ if $Line =~ /= *\(*([\w]*\))/;;
	#Maps equations with +
	@matchesAdd = $Line =~ /\+ *\(*[A-Za-z]\)*/g;
	$Line = oppMapper(\@matchesAdd, $Line, "+") if @matchesAdd;
	#Maps equations with -
	@matchesSub = $Line =~ /\- *\(*[A-Za-z]\)*/g;
	$Line = oppMapper(\@matchesSub,$Line, "-") if @matchesSub;
	#Maps equations with /
	@matchesDiv = $Line =~ /\/ *\(*[A-Za-z]\)*/g;
	print"matchesDiv is @matchesDiv\n";
	$Line = oppMapper(\@matchesDiv, $Line, "/") if @matchesDiv;
	#Maps equations with *
	@matchesTimes = $Line =~ /\* *\(*[A-Za-z]\)*/g;
	$Line = oppMapper(\@matchesTimes, $Line, "*") if @matchesTimes;
	#Maps equations with **/^
	@matchesPowers = $Line =~ /\*\* *\(*[A-Za-z]\)*/g;
	foreach $matchPowers (@matchesPowers) {
		$matchPowers =~ s/\*\* *//;
		$matchPowers =~ s/\(//;
		$matchPowers =~ s/\)//;
		$Line =~ s/\*\* *$matchPowers/\*\*\$$matchPowers/m if $Line =~ /\*\* *[A-Za-z]/;
		$Line =~ s/\*\* *\($matchPowers/\*\*\(\$$matchPowers/m if $Line =~ /\*\* *\(*[A-Za-z]\)*/;
	}
	return $Line;
}

sub oppMapper {
    my @matchArr = @{$_[0]};
    $Line2 = $_[1];
    $sign = $_[2];
    print"matchArr is @matchArr\n";
    print"line is $line\n";
    print"sign is $sign\n";
    foreach $matchEle (@matchArr) {
	    $matchEle =~ s/(\+|\-|\*|\/) *//;
	    $matchEle =~ s/\(//;
	    $matchEle =~ s/\)//;
	    print"matchEle is $matchEle\n";
        $Line2 =~ s/(\+|\-|\*|\/) *\($matchEle/$sign \(\$$matchEle/m if $Line2 =~ /(\+|\-|\*|\/) *\(*[A-Za-z]\)*/;
	    $Line2 =~ s/(\+|\-|\*|\/) *$matchEle/$sign \$$matchEle/m if $Line2 =~ /(\+|\-|\*|\/) *[A-Za-z]/;
    }
    return $Line2;
}

sub ifMapper() {

}

sub whileMapper() {

}

sub forMapper() {

}

sub forEachMapper() {

}

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
			$line =~ s/\("?/ "/;
			$line =~ s/"?\)/\\n"/;
		}
		#Subset 1: deals with Variables, Constants and Maths operations										
		if($line =~ /^[\w]* *= *\(*[\w]*\)*/) {
		    $line = variableMapper($line);
		}
		$line .= ";";
	}
	push(@perlLines,$line);
}
close F;
open $F, '>', "$progName" or die;
foreach $Line (@perlLines) {
	print $F "$Line" if $Line ne "\n";
	print $F "\n";
}
close $F;
