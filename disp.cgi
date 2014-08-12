#!/usr/bin/perl -w

use strict;
use CGI;

my $q = new CGI;

print $q->header(-type=>'image/png',-expires=>'now');

my $pid = $ARGV[0];

($pid =~ /^\d+$/) || (die "Nope");

my $file = "board".$pid.".png";
print `cat $file`;

unlink($file);
