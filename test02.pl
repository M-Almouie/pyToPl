#!/usr/bin/perl -w


%lines = ('g' => 1);
foreach $key (sort keys %lines) {
	print"$key, ";
}
