#!/usr/bin/env perl

use strict;
use encoding 'euc-jp';
use KNP;
use CompoundNounExtractor;

my $cne = new CompoundNounExtractor;

my $buf;

while (<>) {
    $buf .= $_;

    if (/^EOS$/) {
	my $result = new KNP::Result($buf);

	# ¸¶Ê¸
	foreach my $mrph ($result->mrph) {
	    print $mrph->midasi;
	}
	print "\n";

	foreach my $bnst ($result->bnst) {
	    print '¡ú', $bnst->id, "\n";
	    my $word = $cne->ExtractCompoundNounfromBnst($bnst, { longest => 1 });

	    print $word->[0], "\n" if $word;

# 	    foreach my $tmp (@words) {
# 		my ($midasi, $repname) = @$tmp;

# 		print $midasi, "\n";
# 	    }
	}

	$buf = "";
    }
}

