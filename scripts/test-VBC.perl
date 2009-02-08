#!/usr/bin/env perl

# $Id$

# VariableByteCodeのサンプル

################################################
# 使い方
#
# $ cat numbers
# 742235
# 364749
# 811975
# 664420
# 428620
# 900908
# 12040
# 113313
# 543654
# 943224
# $ perl -I./perl scripts/test-VBC.perl -encode numbers > numbers.vbc
# $ file number.vcd 
# number.vcd: data
# $ perl -I./perl scripts/test-VBC.perl -decode number.vcd
# 742235
# 364749
# 811975
# 664420
# 428620
# 900908
# 12040
# 113313
# 543654
# 943224
# $
################################################



use strict;
use utf8;
use Getopt::Long;
use VariableByteCode;

my (%opt);
GetOptions(\%opt, 'encode', 'decode');

&main;

sub main {
    open (F, $ARGV[0]) or die "$!";
    if ($opt{decode}) {
	my $buf;
	while (<F>) {
	    $buf .= $_;
	}

	my @byteCodes = unpack("(c)*", $buf);
	my $numbers = VariableByteCode::decode(\@byteCodes);
	foreach my $n (@$numbers) {
	    print $n . "\n";
	}
    }
    elsif ($opt{encode}) {
	my @numbers;
	while (<F>) {
	    chop;
	    push (@numbers, $_);
	}

	my @byteCodes;
	foreach my $n (@numbers) {
	    my $bytes = VariableByteCode::encode($n);
	    push (@byteCodes, @$bytes);
	}

	foreach my $b (@byteCodes) {
	    print $b;
	}
    }
    close (F);
}

