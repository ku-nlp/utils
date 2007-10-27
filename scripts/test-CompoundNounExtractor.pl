#!/usr/bin/env perl

# $Id$

# test script for CompoundNounExtractor

# echo '自然言語処理を研究する。' | juman | knp -tab -dpnd | perl -I../perl test-CompoundNounExtractor.pl

use strict;
use encoding 'euc-jp';
binmode STDERR, ':encoding(euc-jp)';

use KNP;
use CompoundNounExtractor;
use Getopt::Long;

my (%opt);
GetOptions(\%opt, 'longest', 'clustering', 'mrphnummax=i', 'debug');
&usage if $opt{help};

my $option;
$option->{debug} = 1 if $opt{debug};
$option->{clustering} = 1 if $opt{clustering};
$option->{MRPH_NUM_MAX} = $opt{mrphnummax} if $opt{mrphnummax};
my $cne = new CompoundNounExtractor($option);

my $buf;

while (<>) {
    $buf .= $_;

    if (/^EOS$/) {
	my $result = new KNP::Result($buf);

	# 原文
	foreach my $mrph ($result->mrph) {
	    print $mrph->midasi;
	}
	print "\n";

	foreach my $bnst ($result->bnst) {
	    print STDERR '★ bid:', $bnst->id, "\n";
	    if ($opt{longest}) {

		my $word = $cne->ExtractCompoundNounfromBnst($bnst, { longest => 1 });

		print $word->{midasi}, "\n" if $word;
	    }
	    else {
		my @words = $cne->ExtractCompoundNounfromBnst($bnst);

		foreach my $tmp (@words) {
		    print $tmp->{midasi}, "\n";
		}
	    }
	}

	$buf = "";
    }
}

