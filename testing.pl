#!/usr/bin/perl -w

$sign = "+";
while($line = <STDIN>)
{
    $line =~ s/ \\$sign / - /;
    print"$line\n";
    print"\n";
}

foreach $matchAdd (@matchesAdd) {
		$matchAdd =~ s/\+ *//;
		$matchAdd =~ s/\(//;
		$matchAdd =~ s/\)//;
		$Line =~ s/\+ *\($matchAdd/\+ \(\$$matchAdd/m if $Line =~ /\+ *\(*[A-Za-z]\)*/;
		$Line =~ s/\+ *$matchAdd/\+ \$$matchAdd/m if $Line =~ /\+ *[A-Za-z]/;
	}
	
	#print"matchEle is $matchEle\n";
	    
