#!/usr/bin/env perl

# $Id$

use strict;
use encoding 'euc-jp';
binmode STDERR, ':encoding(euc-jp)';
use Juman;
use DetectPersonAfterJuman;
use Getopt::Long;
my (%opt);
GetOptions(\%opt, 'debug');

my $detectperson = new DetectPersonAfterJuman(\%opt);

my $buf;

while (<>) {
    $buf .= $_;

    if (/EOS/) {
	my $result = new Juman::Result($buf);

	$detectperson->DetectPerson($result);
	$buf = '';
    }
}
