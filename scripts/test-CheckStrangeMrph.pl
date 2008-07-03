#!/usr/bin/env perl

# $Id$

# test script for CheckStrangeMrph

# echo '¤³¤Ê¤£¤À' | juman | knp -tab -dpnd | perl -I../perl test-CheckStrangeMrph.pl

use strict;
use encoding 'euc-jp';
use KNP;
use CheckStrangeMrph;

my $check_strange_mrph = new CheckStrangeMrph;

my $buf;

while (<>) {
    $buf .= $_;

    if (/^EOS$/) {
	my $result = new KNP::Result($buf);

	my @mrphs = $result->mrph;

	for (my $i = 0; $i < @mrphs; $i++) {
	    my $mrph = $mrphs[$i];
	    my $mrph_pre = $i > 0 ? $mrphs[$i-1] : undef;
	    my $mrph_post = $i < @mrphs - 1 ? $mrphs[$i+1] : undef;

	    if ($check_strange_mrph->CheckStrangeHiragana($mrph, $mrph_pre, $mrph_post)) {
		print $mrph->midasi, ": strange\n";
	    }
	}
	undef $buf;
    }
}
