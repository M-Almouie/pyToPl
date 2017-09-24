#!/usr/bin/perl -w

# COMP[29]041 Assignment 1 - 17S2
# Author: Mohamed Daniel Al Mouiee z5114185

open F, '<',"$ARGV[0]" or die;
$progName = $ARGV[0];
$progName =~ s/\.py/\.pl/;
@perlLines =();
$boolIf = 0;
$boolSepLine = 0;
while($line = <F>) {
	chomp $line;
	$line =~  /^(\s*)/;
	$count = length( $1 );
	push(@spaces,$count);
	if($spaces[$#spaces] < $spaces[$#spaces-1]  && $#spaces > 0 ) {
	    $i = 0;
	    while($i < $count) {
	        $s .= " ";
	        $i++;
	    }
	    push(@perlLines,"$s}");
	    $s = "";
	    #next;
	}
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
			$line = printMapper($line);
		}
		#Subset 1: deals with Variables, Constants and Maths operations										
		if($line =~ /^ *\(*[\w]*\)* *= *\(*[\w]*\)*/) {
		    $line = variableMapper($line) if !($line =~ /while|if|print|for|foreach/);
		}
		#Subset 2: deals with simple if, while, for and logical statements	
		if($line =~ /if .*:/) {
		    $boolIf = 1;
		    ifMapper($line);
		    
		    #print"line is $line\n";
		    next;
		}
		if($line =~ /while .*:/) {
		    whileMapper($line);
		    next;
		}
		$line .= ";";
	}
	push(@perlLines,$line);
}
if($spaces[$#spaces] > 0  && $#spaces > 0 ) {
	    push(@perlLines,"}");
}
close F;
#open $F, '>', "$progName" or die;
foreach $Line (@perlLines) {
	print "$Line" if $Line ne "\n";
	print "\n";
}
#close $F;

sub variableMapper {
    my ($Line) = @_;
    ($first, $second) = $Line =~ /^ *([\w]*) *=* *\(*([\w]*\)*)/;
    #print"second is $second\n";
	$Line =~ s/($1)/\$$first /;
	# If there are parentheses (at most 1) that wrap the variables
	$Line =~ s/= *[A-Za-z]+[\w]*/= \$$second/ if $Line =~ /= *([\w]*)/;;
	$Line =~ s/= *\([A-Za-z]+[\w]*\)/= \(\$$second/ if $Line =~ /= *\(*([\w]*\))/;;
	#START HERE
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
    #print"matchArr is @matchArr\n";
    #print"line is $line\n";
    #print"sign is $sign\n";
    foreach $matchEle (@matchArr) {
	    $matchEle =~ s/(\+|\-|\*|\/) *//;
	    $matchEle =~ s/\(//;
	    $matchEle =~ s/\)//;
	    #print"matchEle is $matchEle\n";
        $Line2 =~ s/(\+|\-|\*|\/) *\($matchEle/$sign \(\$$matchEle/m if $Line2 =~ /(\+|\-|\*|\/) *\(*[A-Za-z]\)*/;
	    $Line2 =~ s/(\+|\-|\*|\/) *$matchEle/$sign \$$matchEle/m if $Line2 =~ /(\+|\-|\*|\/) *[A-Za-z]/;
    }
    return $Line2;
}

sub ifMapper {
    my ($Line) = @_;
    $boolSepLine = 0;
	$boolSepLine = 1 if !($Line =~ /: *[A-Za-z]/);
	(my $first) = $Line =~ /if *(.*):/;
	$first = variableMapper($first);
	$Line =~ s/if .*($1)/if\($first\)/;
	if ($boolSepLine == 0) {
	    (my $second) = $Line =~ /:(.*)/;
	    $Line =~ s/:.*/ \{/;
	    push(@perlLines,$Line);
	    $second =~ s/^ *//;
	    $second = variableMapper($second) if !($second =~ /print/);
	    $second = ifMapper($second) if $second =~ /if *:/;
	    $second =~ s/^/    /;
	    $second .= ";";
	    push(@perlLines,$second);
	    push(@perlLines,"}");
	} else {
	    $Line =~ s/:.*/ \{/;
	    push(@perlLines,$Line);
	}
}

sub whileMapper {
    my ($Line) = @_;
    $boolSepLine = 0;
	$boolSepLine = 1 if !($Line =~ /: *[A-Za-z]/);
	(my $first) = $Line =~ /while *(.*):/;
	$first = variableMapper($first);
	$Line =~ s/while .*($1)/while\($first\)/;
	if ($boolSepLine == 0) {
	    (my $second) = $Line =~ /:(.*)/;
	    $Line =~ s/:.*/ \{/;
	    push(@perlLines,$Line);
	    $second =~ s/^ *//;
	    $second = variableMapper($second) if !($second =~ /print/);
	    $second = ifMapper($second) if $second =~ /while *:/;
	    $second =~ s/^/    /;
	    $second .= ";";
	    push(@perlLines,$second);
	    push(@perlLines,"}");
	} else {
	    $Line =~ s/:.*/ \{/;
	    push(@perlLines,$Line);
	}
}

sub forMapper {

}

sub forEachMapper {

}

sub printMapper {
	my ($line) = @_;
	(my $mat) = $line =~ /print\("*(.*)"*\)/;
	$mat =~ s/"//;
	$mat = variableMapper($mat) if !($line =~ /\(".*"\)/);	
	$line =~ s/\(.*\)/ "$mat\\n"/ if !($line =~ /\(".*"\)/);
	$line =~ s/\(.*\)/ "$mat\\n"/;
	return $line;
}

