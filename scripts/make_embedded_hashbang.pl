#!/usr/bin/env perl

use v5.14;
#use common::sense;
use strict;
use warnings;

my $comm = "";
my $file = "";
FILE:
while ($file = shift @ARGV) {
	open(my $fh, "<", $file);
	while (<$fh>) {
		if (s/.+?#!(.+)/$1/) {
			$comm = $_ =~ s/%%/$file/er;
			$comm =~ s/^\s+|\s$//g;
			print "$file |= $comm : Do you wish to execute this? [yn] > ";
			chomp ($_ = <STDIN>);
			qx/$comm/ if (m/^(?:y(?:es){0,1})/i);
			next FILE;
		}
	}
}
