#!/usr/bin/perl -w

# COMP[29]041 Assignment 1 - 17S2
# Author: Mohamed Daniel Al Mouiee z5114185

$s = "";
$boolSepLine = 0;
@lists = ();
@dicts = ();
while($line = <>) {
	chomp $line;
	#finding number of spaces at the beginning of the line
	$line =~  /^(\s*)/;
	$count = length( $1 );
	push(@spaces,$count);
	while($spaces[$#spaces] <= $spaces[$#spaces-1] -4  && $#spaces > 0 ) {
	    $i = 0;
	    while($i < $spaces[$#spaces-1] -4) {
	        $s .= " ";
	        $i++;
	    }
	    push(@perlLines,"$s}");
	    $s = "";
	    $spaces[$#spaces-1] -= 4;
	}
	# Checks for empty lines in .py file
	if($line =~ /^ *$/) {
		push(@perlLines,"\n");
		next;
	}
	#Subset 0
	if($line =~ /\/python[23]/) {
		$line =~ s/\/python[23]/\/perl -w/;
	}elsif($line =~ /import .*/) {
	    $line =~ s/^.*$//;
	}elsif($line =~ /sys\.stdin\..+/ or $line =~ /sys\.stdout\..*/) {
		$line = sysMapper($line);
		$line .= ";";
    } 
	else{
		if($line =~ /print\(.*\)/) {
			$line = printMapper($line);
		}
		#Subset 1: deals with Variables, Constants and Maths operations										
		if($line =~ /^ *\(*[\w]*\)* *([<>=]+ *\(*\w+)\)*/) {
		    $line = variableMapper($line) if !($line =~ /elif|else|while|if|print|for|foreach|break|continue|sorted\(/);
		}
		if($line =~ /= *.*\.keys\(/) {
			$line = keysMapper($line);
		}
		#Subset 2: deals with simple if/elif/else, while, for and logical statements	
		if($line =~ /if .*:/) {
		    ifMapper($line);
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
		if($line =~ /for .*:/) {
		    forMapper($line);
		    next;
		}
		#deals with lists
		if($line =~ /\[.*\]/ and !($line =~ /print/)) {
		    $line = listMapper($line);
		}
		if($line =~ /\{.*\}/) {
		    $line = dictMapper($line);
		}
		if($line =~ /\b(\.append|\.pop|len\()\b/) {
		    $line = listMethMapper($line);
		}
		if($line =~ /=?.*len\(.*\)/) {
		    $line = lenMapper($line);
		}
		if($line =~ /sorted\(/) {
		    $line = sortedMapper($line);
		}
		# Assuming continue and break have at least one space before them
	    $line =~ s/ break/last/;
	    $line =~ s/ continue/next/;
		$line .= ";" if(!($line =~ /\[/));
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
foreach $Line (@perlLines) {
    if($Line =~ /;.*;/) {
        ($random) = $Line =~ /;(.*);/;
        $random = variableMapper($random);
        $Line =~ s/;.*;/;$random;/;
    }
	print "$Line" if $Line ne "\n";
	print "\n";
}
# End of Program

sub variableMapper {
    my ($line) = @_;
    my ($first, $second) = $line =~ /^ *([\w]*) *[\%\-\*\/\+!=<>]* *\(*([\w]*\)*)/;
    my ($str) = strOfLists();
    $str .= strOfDicts();
    $line =~ s/$first/\@$first / if(($str =~ /\|?$first \|?/));
	$line =~ s/$first/\$$first / if(!($str =~ /\|?$first \|?/));
	# If there are parentheses (at most 1) that wrap the variables
	if(!($second =~ /len$/)) {
        $line =~ s/= *[A-Za-z]+[\w]*/= \$$second/ if $line =~ /= *([\w]*)/;
        $line =~ s/<= *[A-Za-z]+[\w]*/<= \$$second/ if $line =~ /<= *([\w]*)/;
        $line =~ s/>= *[A-Za-z]+[\w]*/>= \$$second/ if $line =~ />= *([\w]*)/;
        $line =~ s/< *[A-Za-z]+[\w]*/< \$$second/ if $line =~ /< *([\w]*)/;
        $line =~ s/> *[A-Za-z]+[\w]*/> \$$second/ if $line =~ /> *([\w]*)/;
        $line =~ s/!= *[A-Za-z]+[\w]*/!= \$$second/ if $line =~ /!= *([\w]*)/;
        $line =~ s/= *\([A-Za-z]+[\w]*\)/= \(\$$second/ if $line =~ /= *\(*([\w]*\))/;
    }
    #Maps equations with + 
    @matchesAdd = $line =~ /\+ *\(*[A-Za-z]\)*/g;
    $line = oppMapper(\@matchesAdd, $line, "+") if @matchesAdd;
    #Maps equations with -
    @matchesSub = $line =~ /\- *\(*[A-Za-z]\)*/g;
    $line = oppMapper(\@matchesSub,$line, "-") if @matchesSub;
    #Maps equations with /
    @matchesDiv = $line =~ /\/ *\(*[A-Za-z]\)*/g;
    $line = oppMapper(\@matchesDiv, $line, "/") if @matchesDiv;
    #Maps equations with *
    @matchesTimes = $line =~ /\* *\(*[A-Za-z]\)*/g;
    $line = oppMapper(\@matchesTimes, $line, "*") if @matchesTimes;
    #Maps equations with %/mod
    @matchesMod = $line =~ /\% *\(*[A-Za-z]\)*/g;
    $line = oppMapper(\@matchesMod, $line, "%");
    #Maps equations with **/^
    @matchesPowers = $line =~ /\*\* *\(*[A-Za-z]\)*/g;
    foreach $matchPowers (@matchesPowers) {
	    $matchPowers =~ s/\*\* *//;
	    $matchPowers =~ s/\(//;
	    $matchPowers =~ s/\)//;
	    $line =~ s/\*\* *$matchPowers/\*\*\$$matchPowers/m if $line =~ /\*\* *[A-Za-z]/;
	    $line =~ s/\*\* *\($matchPowers/\*\*\(\$$matchPowers/m if $line =~ /\*\* *\(*[A-Za-z]\)*/;
    }
	$line =~ s/= *\$/= / if $line =~ /\$\w+\.pop\(/;
	return $line;
}

sub oppMapper {
    my @matchArr = @{$_[0]};
    my $line = $_[1];
    my $sign = $_[2];
    #print"matchArr is @matchArr\n";
    #print"line is $line\n";
    #print"sign is $sign\n";
    foreach $matchEle (@matchArr) {
	    $matchEle =~ s/(\+|\-|\*|\/|\%) *//;
	    $matchEle =~ s/\(//;
	    $matchEle =~ s/\)//;
	    #print"matchEle is $matchEle\n";
        $line =~ s/(\+|\-|\*|\/|\%) *\($matchEle/$sign 
        \(\$$matchEle/m if $line =~ /(\+|\-|\*|\/|\%) *\(*[A-Za-z]\)*/;
	    $line =~ s/(\+|\-|\*|\/|\%) *$matchEle/$sign \$$matchEle/m 
	    if $line =~ /(\+|\-|\*|\/|\%) *[A-Za-z]/;
    }
    $line =~ s/\/{2}/\//;
    return $line;
}

sub ifMapper {
    my ($line) = @_;
    $boolSepLine = 0;
	$boolSepLine = 1 if !($line =~ /: *[A-Za-z]/);
	(my $first) = $line =~ /if *(.*):/;
    $first =~ s/\+/\\+/;
	$first =~ s/\*/\\*/;
	if($first =~ /and|or|not/) {
        $first = logicMapper($first); 
    }else {
	    $first = variableMapper($first) if (!($first =~ /\[/));
	    $first = listMapper($first) if ($first =~ /\[/);
	}
    $line =~ s/if .*:/if\($first\):/;
    if ($boolSepLine == 0) {
        (my $second) = $line =~ /:(.*)/;
        $line =~ s/:.*/ \{/;
        push(@perlLines,$line);
        $second =~ s/^ *//;
        $second = variableMapper($second) if !($second =~ /print/);
        $second = ifMapper($second) if $second =~ /if *:/;
        $second =~ s/^/    /;
        $second .= ";";
        push(@perlLines,$second);
        push(@perlLines,"}");
    } else {
        $line =~ s/elif/elsif/;
        $line =~ s/:.*/ \{/;
        push(@perlLines,$line);
    }
}

sub elseMapper {
    my ($line) = @_;
    $line =~ s/else:/else {/;
    push(@perlLines,$line);
    return $line;
}

sub whileMapper {
    my ($line) = @_;
    $boolSepLine = 0;
	$boolSepLine = 1 if !($line =~ /: *[A-Za-z]/);
	(my $first) = $line =~ /while *(.*):/;
	$first =~ s/\+/\\+/;
	$first =~ s/\*/\*/;
	if($first =~ /and|or|not/) {
        $first = logicMapper($first); 
    }else {
	    $first = variableMapper($first) if (!($first =~ /\[/));
	    $first = listMapper($first) if ($first =~ /\[/);
	}
	$line =~ s/while .*:/while\($first\):/;
	if ($boolSepLine == 0) {
	    (my $second) = $line =~ /:(.*)/;
	    $line =~ s/:.*/ \{/;
	    push(@perlLines,$line);
	    $second =~ s/^ *//;
	    $second = variableMapper($second) if !($second =~ /print/);
	    $second = ifMapper($second) if $second =~ /while *:/;
	    $second =~ s/^/    /;
	    $second .= ";";
	    push(@perlLines,$second);
	    push(@perlLines,"}");
	} else {
	    $line =~ s/:.*/ \{/;
	    push(@perlLines,$line);
	}
}

sub logicMapper() {
    my ($line) = @_;
    my ($first) = $line =~ /^(.*?) \b(or|and|not)\b/;
    $first = variableMapper($first);
    $final .= "$first and ";
    @comp = $line =~ /\b(and|or|not)\b (.*)/g;
    $count = 1;
    while($count < @comp) {
        $comp[$count] = variableMapper($comp[$count]);
        $final .= $comp[$count];
        $count++;
    }
    return $final;
}

sub sysMapper {
    (my $line) = @_;
    if($line =~ /sys\.stdout\.write\(.*\)/) {
        (my $first) = $line =~ /sys\.stdout\.write\((.*)\)/;
        $first = variableMapper($first) if !($first =~ /".*"/);
        $line =~ s/sys.*/print $first/ if $line =~ /".*"/;
        $line =~ s/sys.*/print "$first"/ if !($line =~ /".*"/);
    } elsif($line =~ /^ *\w+ *= *int\(sys\.stdin\.readline\(\)\)/) {
        (my $first) = $line =~ /^ *(\w+) *= *int\(sys\.stdin\.readline\(\)\)/;
        $first = variableMapper($first);
        $line =~ s/($1).*/$first= \<STDIN\>/;
    }else{#($line =~ /^ *\w+ *= *\(sys\.stdin\.readlines\(\)\)/) {
        (my $first) = $line =~ /^ *(\w+) *= *sys\.stdin\.readlines\( *\)/;
        $first =~ s/^/\@/;
        push(@lists, $first);
        $line =~ s/^.*$/$first = <STDIN>/;
    }
    #lines = sys.stdin.readlines();
    return $line;
}

sub forMapper {
    (my $line) = @_;
    if($line =~ /for *(\w+) *in * range\((.*)\) *:/){
        (my $first, my $second) = $line =~ /for *(\w+) *in * range\((.*)\) *:/;
        $first = variableMapper($first);
        (my @bounds) = split(/,/,$second);
        $second = "";
        while(@bounds) {
            $temp =  shift(@bounds);
            $temp = variableMapper($temp) if $temp =~ /[A-Za-z]/;
            $second .= $temp;
            $second .= "," if @bounds; 
        }
        (my $num) = $second =~ /, *(.*)/;
        $num .= "-1";
        $second =~ s/,.*/.. $num/;
        $line =~ s/for .*/foreach $first($second) {/;
        push(@perlLines,$line);
    }
    if($line =~ /for *(\w+) *in * sys.stdin *:/) {
         (my $first) = $line =~ /for *(\w+) *in/;
        $first = variableMapper($first);
        $line =~ s/^.*$/foreach $first(<STDIN>) {/;
        push(@perlLines,$line);
    }
}

sub printMapper {
	my ($line) = @_;
	(my $end) = $line =~ /end *= *'(.*)'/;
	(my $mat) = $line =~ /print\("*(.*)"*\)/;
    if(!($line =~ /\%/)) {
	    if(($mat =~ /^ *$/)) {
	        $line =~ s/^.*$/print"\\n"/;
	        return $line
	    }
	    $mat =~ s/"//;
	    $mat = variableMapper($mat) if(!($line =~ /\(".*".*\)/) and !($line =~ /\[/));
	    if($line =~ /end *= *'/) {
	        if ($line =~ /\[/) {
	            (my $list) = $line =~ /([A-Za-z]\w+\[.*\])/; 
	            $list = listMapper($list);
	            $list =~ s/;//;
	            $line =~ s/[A-Za-z]\w+\[.*\]/$list/;
	            $line =~ s/\(.*\)/ $mat,"$end"/ if(!($line =~ /\(".*".*\)/));
	            $line =~ s/\, *end.*,/,/;
	        } else{
	            $line =~ s/\(.*\)/ $mat,"$end"/ if(!($line =~ /\(".*".*\)/) and !($line =~ /\[/));
	            $line =~ s/\, *end.*,/,/;	            
	        }
	        if($line =~ /"/) {
	            $line =~ s/\, end.*//;
	            $mat =~ s/\, end.*//;
	            $line =~ s/\(.*/ "$mat$end"/ if($line =~ /\(".*".*/ and !($line =~ /\[/));
	        }
	    } else {
	        
	        $line =~ s/\(.*\)/ $mat,"\\n"/ if(!($line =~ /\(".*"\)/) and !($line =~ /\[/));
	        $line = listMapper($line) if ($line =~ /\[/);
	        print"line is $line\n";
	        $line =~ s/\(|\)/ "/g;
	    }
	}else {
	    (my $vars) = $line =~ /" *\% +(.*)\)/;
	    $vars =~ s/\(//;
	    $vars =~ s/\)//;
	    $vars =~ s/, *end.*//;
	    @vars = split(/ *, */,$vars);
	    $strList = strOfLists();
	    $strDict = strOfDicts();
	    #$temp = shift @vars;
	    while(@vars) {
	        $temp = shift @vars;
	        
	        $line =~ s/\%[a-z]/\$$temp/ if(!($strList =~ /\|$temp\|/) and !($strDict =~ /\|$temp\|/));
	        $line =~ s/\%\w/\@$temp/ if($strList =~ /\|$temp\|/);
	        $line =~ s/\%\w/\%$temp/ if($strDict =~ /\|$temp\|/);
	    }
	    $line =~ s/\(/ /;
	    if($line =~ /, *end *=/) {
	        (my $end1) = $line =~ /end *= *'(.*)'/;
	        $line =~ s/\%.*/,/;
	        $line =~ s/" *,.*$/$end1"/;
	    } else {
	        $line =~ s/\%.*//;
	        $line =~ s/" *$/\\n"/;
	    }
	}
	return $line;
}

sub listMapper {
    (my $line) = @_;
    if($line =~ /= *\w/) {
        (my $first, my $sign, my $second) = $line =~ /^ *(\w+\[?.*\]?) *([=<>!]+) *\[?(.*?)\]?/;
        (my $temp ) = $first;
  
        $temp =~ s/\[?.*\]//;
        push(@lists,$temp);
        $first =~ s/^/\@/ if !($first =~ /\[/);
        $first =~ s/^/\$/ if ($first =~ /\[/);
        $first =~ s/\[/[\$/ if $first =~ /\[[A-Za-z]/;
        if (!($first =~ /\[/)) {
             $line =~ s/^.*$/$first$sign ($second)/;
        } else {
            (my $third) = $line =~ /[=<>!]+ *(.*)/;
            @segs = split(/[\+\-\*\/\%]+ */,$third);
            foreach $seg(@segs) {
                (my $temp2) = $seg;
                $seg =~ s/\[/\\[/;
                $seg =~ s/\]/\\]/;
                if($temp2 =~ /\[[A-Za-z]\w*/) {
                    (my $varMat) = $temp2 =~ /\[([A-Za-z]\w*)/;
                    $varMat = variableMapper($varMat);
                    $temp2 =~ s/\[.*?\]/[$varMat\]/;
                    $temp2 =~ s/ +//;
                }
                $third =~ s/$seg/\$$temp2/ if($seg =~ /[A-Za-z]/ and !($seg =~ /\"|\'/));
            }
            $line =~ s/^.*$/$first$sign $third/;
        }
    } else {
       
        (my $first2) = $line =~ /(\w+\[.*\])/;
        (my $temp3) = $first2;
        $temp3 =~ s/\[/\\[/;
        $temp3 =~ s/\]/\\]/;
        $first2 =~ s/^/\$/;
        $first2 =~ s/\[/[\$/ if $first2 =~ /\[[A-Za-z]/;
        $line =~ s/$temp3/$first2/;
    }
    $line =~ s/$/;/;
    return $line;
}

sub listMethMapper {
    (my $Line) = @_;
    if($line =~ /\.append/) {
        (my $first, my $second) = $line =~ /(\w+)\.append\((\"?\w+\"?)\)/;
        $line =~ s/$first.*/push(\@$first,\$$second)/ if !($second =~/"/);
        $line =~ s/$first.*/push(\@$first,$second)/ if $second =~/"/;
    }
    if($line =~ /\.pop\(\)/) {
        (my $first) = $line =~ /(\w+)\.pop/;
        $line =~ s/$first.*/pop(\@$first)/;
    }elsif($line =~ /\.pop\(\d+\)/) {
        (my $first, my $second) = $line =~ /(\w+)\.pop\((\d+)\)/;
        $line =~ s/$first.*/splice(\@$first,$second,1)/;
    }
    return $line;
}

sub lenMapper {
    (my $line) = @_;
    (my $str) = strOfLists();
    (my $first) = $line =~ /len\((.*)\)/;
    if($str =~ /$first/) {
        $line =~ s/len\(.*\)/\@$first/;
    }else {
        $line =~ s/len\(.*\)/length(\$$first)/;
    }
    return $line;
}

sub sortedMapper {
    (my $line) = @_;
    (my $str) = strOfLists();
    $line =~ s/sorted\(/sort\(/;
    (my $first) = $line =~ /sort\((.*)\)/;
    if($str =~ /\|?$first\|?/) {
        $line =~ s/sort\(.*\)/sort(\@$first)/;
    }else {
        $line =~ s/sort\(.*\)/sort(\$$first)/;
    }
    return $line;
}


sub strOfLists {
    (my $str) = "";
    foreach $list(@lists) {
        $str .= $list."|";
    }
    $str =~ s/\|$//;
    return $str;
}

sub dictMapper {
    (my $line) = @_;
    (my $first, my $sign, my $second) = $line =~ /^ *(\w+\[?.*\]?) *([=<>!]+) *\{?(.*)\}?/;
    (my $temp ) = $first;
    $temp =~ s/\}?//;
    $temp =~ s/\{?//;
    push(@dicts,$temp);
    $first =~ s/^/\%/ if !($first =~ /\[/);
    $first =~ s/^/\$/ if ($first =~ /\[/);
    if (!($first =~ /\{/)) {
         $line =~ s/^.*$/$first$sign ($second)/;
    }
    $line =~ s/:/=>/g;
    $line =~ s/\}//;
    return $line;
}

sub keysMapper {
	(my $line) = @_;
	(my $listName) = $line =~ /= *(.*)\.keys\(/;
	$hashName = $listName;
	$listName =~ s/^ *\$/\@/;
	$hashName =~ s/^ *\$/\%/;
	$listName =~ s/\..*//;
	$hashName =~ s/\..*//;
	$listName .= "List";
	$line =~ s/^.*$/$listName = \(\);\nforeach \$key (sort keys $hashName) \{\n    push($listName,\$key);\n\}/;
	return $line;
}

sub strOfDicts {
    (my $str) = "";
    foreach $dict(@dicts) {
        $str .= $dict."|";
    }
    $str =~ s/\|$//;
    return $str;
}
