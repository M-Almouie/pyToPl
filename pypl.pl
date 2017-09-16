#!/usr/bin/perl -w

# COMP[29]041 Assignment 1 - 17S2
# Author: Mohamed Daniel Al Mouiee z5114185


sub variableMapper {
    my ($Line) = @_;
    ($first, $second) = $Line =~ /^\t*([\w]*) *= *\(*([\w]*\)*)/;
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
    foreach $matchEle (@matchArr) {
	    $matchEle =~ s/(\+|\-|\*|\/) *//;
	    $matchEle =~ s/\(//;
	    $matchEle =~ s/\)//;
	    $Line2 =~ s/(\+|\-|\*|\/) *\($matchEle/$sign \(\$$matchEle/m if $Line2 =~ /(\+|\-|\*|\/) *\(*[A-Za-z]\)*/;
	    $Line2 =~ s/(\+|\-|\*|\/) *$matchEle/$sign \$$matchEle/m if $Line2 =~ /(\+|\-|\*|\/) *[A-Za-z]/;
    }
    return $Line2;
}

sub ifMapper {
    my ($Line) = @_;
    (my $first, my $second) = $Line =~ /if(.*):(.*)?/;
    $Line =~ s/($1)/\($first\)/;
    $Line =~ s/:.*/ \{/;
    push(@perlLines,$Line);
    if($second =~ / *[A-Za-z]/) {
    	$second =~ s/^/	/;
    	print"NOPE\n";
    	push(@perlLines,$second);
    	push(@perlLines,"}");
    }
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
$i=1;
while($line = <F>) {
	chomp $line;
	#Check for tabs at the beginning of a line S
	#SOURCE: https://stackoverflow.com/questions/3916852/how-can-i-count-the-amount-of-spaces-at-the-start-of-a-string-in-perl
	$startSpaces = $line;
	$startSpaces =~ /^(\t*)/;
	$countSpaces = length( $1 );
	print"num of spaces $countSpaces\n";
	# Checks for empty lines in .py file
	if($line eq "") {
		push(@perlLines,"\n");
		$i++;
		next;
	}
	#Subset 0
	if($line =~ /\/python[23]/) {
		$line =~ s/\/python[23]/\/perl -w/;
	} else{
		if($line =~ /print\(".*"\)/) {
			$line =~ s/\("?/ "/;
			$line =~ s/"?\)/\\n"/;
		}
		if($line =~ /print\([A-Za-z].*\)/) {
			($var) = $line =~ /print\(([A-Za-z].*)\)/;
			$line =~ s/\(/ "/;
			$line =~ s/\)/"/;
			$line =~ s/($var)/\$$var/;
		}
		#Subset 1: deals with Variables, Constants and Maths operations										
		if($line =~ /^\t*[\w]* *= *\(*[\w]*\)*/) {
		    $line = variableMapper($line);
		}
		#Subset 2: deals with simple if, while, for and logical statements	
		if($line =~ /if .*:/) {
		    ifMapper($line);
		    $i++;
		    next;
		}
		#if($line =~ /while .*:/) {
		#    $line = whileMapper($line);
		#}
		$line .= ";";
	}
	push(@perlLines,$line);
	$i++;
}
close F;
open $F, '>', "$progName" or die;
foreach $Line (@perlLines) {
	print $F "$Line" if $Line ne "\n";
	print $F "\n";
}
close $F;
