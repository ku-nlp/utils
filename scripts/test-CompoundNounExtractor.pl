#!/usr/bin/env perl

# $Id$

# test script for CompoundNounExtractor

# echo '自然言語処理を研究する。" | juman | knp -tab -dpnd | perl -I../perl test-CompoundNounExtractor.pl

use strict;
use encoding 'euc-jp';
use KNP;
use CompoundNounExtractor;
use Getopt::Long;

my (%opt);
GetOptions(\%opt, 'longest');
&usage if $opt{help};

my $cne = new CompoundNounExtractor;

my $buf;

while (<>) {
    $buf .= $_;

    if (/^EOS$/) {
	my $result = new KNP::Result($buf);

	# 原文
	foreach my $mrph ($result->mrph) {
	    print $mrph->midasi;
	}
	print "\n\n";

	foreach my $bnst ($result->bnst) {
	    print '★', $bnst->id, "\n";
	    if ($opt{longest}) {

		my $word = $cne->ExtractCompoundNounfromBnst($bnst, { longest => 1 });

		print $word->[0], "\n" if $word;
	    }
	    else {
		my @words = $cne->ExtractCompoundNounfromBnst($bnst);

		foreach my $tmp (@words) {
		    my ($midasi, $repname) = @$tmp;

		    print $midasi, "\n";
		}
	    }
	}

	$buf = "";
    }
}

