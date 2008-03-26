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
GetOptions(\%opt, 'longest', 'clustering', 'mrphnummax=i', 'lengthmax=i', 'length_max_one_word_each=i', 'centered_dot_num_max=i', 'get_verbose', 'connect_hyphen', 'no_check_same_char_type', 'debug', 'no_yomi_in_repname', 'array_input');
&usage if $opt{help};

my $option;
$option->{debug} = 1 if $opt{debug};
$option->{clustering} = 1 if $opt{clustering};
$option->{get_verbose} = 1 if $opt{get_verbose};
$option->{MRPH_NUM_MAX} = $opt{mrphnummax} if $opt{mrphnummax};
$option->{LENGTH_MAX} = $opt{lengthmax} if $opt{lengthmax};
$option->{LENGTH_MAX_ONE_WORD_EACH} = $opt{length_max_one_word_each} if $opt{length_max_one_word_each};
$option->{CENTERED_DOT_NUM_MAX} = $opt{centered_dot_num_max} if $opt{centered_dot_num_max};
$option->{connect_hyphen} = $opt{connect_hyphen} if $opt{connect_hyphen};
$option->{no_check_same_char_type} = $opt{no_check_same_char_type} if $opt{no_check_same_char_type};
$option->{no_yomi_in_repname} = $opt{no_yomi_in_repname} if $opt{no_yomi_in_repname};

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

	# クラスタリング用
	if ($opt{array_input}) {
	    my @bnsts = $result->bnst;

	    my $option;
	    $option->{longest} = 1 if $opt{longest};
	    my @words = $cne->ExtractCompoundNounfromBnst(\@bnsts, $option);

	    foreach my $tmp (@words) {
		print "midasi:$tmp->{midasi} repname:$tmp->{repname}";
		print " verbose:$tmp->{verbose}" if $opt{get_verbose};
		print " longest★" if defined $tmp->{longest_flag};
		print "\n\n";
	    }
	}
	else {

	    foreach my $bnst ($result->bnst) {
		print STDERR '★ bid:', $bnst->id, "\n";
		if ($opt{longest}) {

		    my $word = $cne->ExtractCompoundNounfromBnst($bnst, { longest => 1 });

		    if ($word) {
			print "midasi:$word->{midasi} repname:$word->{repname}\n\n";
		    } 
		}
		else {
		    my @words = $cne->ExtractCompoundNounfromBnst($bnst);

		    foreach my $tmp (@words) {
			print "midasi:$tmp->{midasi} repname:$tmp->{repname}";
			print " verbose:$tmp->{verbose}" if $opt{get_verbose};
			print "\n\n";
		    }
		}
	    }
	}

	$buf = '';
    }
}

