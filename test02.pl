#!/usr/bin/perl -w

@lines = (11,22,33,44,55);
@num = splice(@lines,3,1);
print"num is @num\n";
