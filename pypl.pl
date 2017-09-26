#!/usr/bin/perl -w

# COMP[29]041 Assignment 1 - 17S2
# Author: Mohamed Daniel Al Mouiee z5114185

open F, '<',"$ARGV[0]" or die;
$progName = $ARGV[0];
$progName =~ s/\.py/\.pl/;
$s = "";
$boolSepLine = 0;
while($line = <F>) {
	chomp $line;
	#finding number of spaces at the beginning of the line
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
		if($line =~ /^ *\(*[\w]*\)* *[<>=]* *\(*[\w]*\)*/) {
		    $line = variableMapper($line) if !($line =~ /elif|else|while|if|print|for|foreach|break|continue/);
		}
		#Subset 2: deals with simple if/elif/else, while, for and logical statements	
		if($line =~ /if .*:/) {
		    ifMapper($line);
		    #print"line is $line\n";
		    next;
		}
		if($line =~ /else *:/) {
		    $line = elseMapper($line);
		    next;
		}
		if($line =~ /while .*:/) {
		    whileMapper($line);
		    next;
		}
		# Assuming continue and break have at least one space before them
	    $line =~ s/ break/last/;
	    $line =~ s/ continue/next/;
		$line .= ";";
	}
	push(@perlLines,$line);
}
$j = 0;
$i = $spaces[$#spaces];
while($i > 0  && $#spaces > 0 ) {
        $sp = "";
        while ($j < $i-4) {
            $sp .= " ";
            $j++;
        }
	    push(@perlLines,"$sp}");
        $i -= 4;
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
    ($first, $second) = $Line =~ /^ *([\w]*) *[\%\-\*\/\+!=<>]* *\(*([\w]*\)*)/;
    #print"second is $second\n";
	$Line =~ s/($1)/\$$first /;
	# If there are parentheses (at most 1) that wrap the variables
	$Line =~ s/= *[A-Za-z]+[\w]*/= \$$second/ if $Line =~ /= *([\w]*)/;
	$Line =~ s/<= *[A-Za-z]+[\w]*/<= \$$second/ if $Line =~ /<= *([\w]*)/;
	$Line =~ s/>= *[A-Za-z]+[\w]*/>= \$$second/ if $Line =~ />= *([\w]*)/;
	$Line =~ s/< *[A-Za-z]+[\w]*/< \$$second/ if $Line =~ /< *([\w]*)/;
	$Line =~ s/> *[A-Za-z]+[\w]*/> \$$second/ if $Line =~ /> *([\w]*)/;
	$Line =~ s/!= *[A-Za-z]+[\w]*/!= \$$second/ if $Line =~ /!= *([\w]*)/;
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
	#Maps equations with %/mod
	@matchesMod = $Line =~ /\% *\(*[A-Za-z]\)*/g;
	$Line = oppMapper(\@matchesMod, $Line, "%");
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
	    $matchEle =~ s/(\+|\-|\*|\/|\%) *//;
	    $matchEle =~ s/\(//;
	    $matchEle =~ s/\)//;
	    #print"matchEle is $matchEle\n";
        $Line2 =~ s/(\+|\-|\*|\/|\%) *\($matchEle/$sign \(\$$matchEle/m if $Line2 =~ /(\+|\-|\*|\/|\%) *\(*[A-Za-z]\)*/;
	    $Line2 =~ s/(\+|\-|\*|\/|\%) *$matchEle/$sign \$$matchEle/m if $Line2 =~ /(\+|\-|\*|\/|\%) *[A-Za-z]/;
    }
    return $Line2;
}

sub ifMapper {
    my ($Line) = @_;
    $boolSepLine = 0;
	$boolSepLine = 1 if !($Line =~ /: *[A-Za-z]/);
	(my $first) = $Line =~ /if *(.*):/;
    $Line =~ s/\+/\\+/;
	$Line =~ s/\*/\*/;
	if($first =~ /and|or|not/) {
        $first = logicMapper($first); 
    }else {
	    $first = variableMapper($first);
	}
    $Line =~ s/if .*:/if\($first\):/;
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
        $Line =~ s/elif/elsif/;
        $Line =~ s/:.*/ \{/;
        push(@perlLines,$Line);
    }
}

sub elseMapper {
    my ($line) = @_;
    $line =~ s/else:/else {/;
    push(@perlLines,$line);
    return $line;
}

sub whileMapper {
    my ($Line) = @_;
    $boolSepLine = 0;
	$boolSepLine = 1 if !($Line =~ /: *[A-Za-z]/);
	(my $first) = $Line =~ /while *(.*):/;
	$Line =~ s/\+/\\+/;
	$Line =~ s/\*/\*/;
	if($first =~ /and|or|not/) {
        $first = logicMapper($first); 
    }else {
	    $first = variableMapper($first);
	}
	$Line =~ s/while .*:/while\($first\):/;
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

sub logicMapper() {
    my ($Line) = @_;
    my ($first) = $Line =~ /^(.*?) \b(or|and|not)\b/;
    $first = variableMapper($first);
    $final .= "$first and ";
    @comp = $Line =~ /\b(and|or|not)\b (.*)/g;
    $count = 1;
    while($count < @comp) {
        $comp[$count] = variableMapper($comp[$count]);
        $final .= $comp[$count];
        $count++;
    }
    return $final;
}

sub forMapper {

}

sub forEachMapper {

}

sub printMapper {
	my ($line) = @_;
	(my $mat) = $line =~ /print\("*(.*)"*\)/;
	if(($mat =~ /^ *$/)) {
	    $line =~ s/^.*$/print"\\n"/;
	    return $line
	}
	$mat =~ s/"//;
	$mat = variableMapper($mat) if !($line =~ /\(".*"\)/);
	$line =~ s/\(.*\)/ "$mat\\n"/ if !($line =~ /\(".*"\)/);
	$line =~ s/\(.*\)/ "$mat\\n"/;
	return $line;
}
