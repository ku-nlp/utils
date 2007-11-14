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
GetOptions(\%opt, 'longest', 'clustering', 'mrphnummax=i', 'lengthmax=i', 'length_max_one_word_each=i', 'centered_dot_num_max=i', 'get_verbose', 'debug');
&usage if $opt{help};

my $option;
$option->{debug} = 1 if $opt{debug};
$option->{clustering} = 1 if $opt{clustering};
$option->{get_verbose} = 1 if $opt{get_verbose};
$option->{MRPH_NUM_MAX} = $opt{mrphnummax} if $opt{mrphnummax};
$option->{LENGTH_MAX} = $opt{lengthmax} if $opt{lengthmax};
$option->{LENGTH_MAX_ONE_WORD_EACH} = $opt{length_max_one_word_each} if $opt{length_max_one_word_each};
$option->{CENTERED_DOT_NUM_MAX} = $opt{centered_dot_num_max} if $opt{centered_dot_num_max};
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
		    print $tmp->{midasi};
		    print " $tmp->{verbose}" if $opt{get_verbose};
		    print "\n";
		}
	    }
	}

	$buf = '';
    }
}

