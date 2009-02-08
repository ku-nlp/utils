package VariableByteCode;

# $Id$

###############################
# VBCのエンコード／デコード関数
###############################

use strict;
use utf8;

sub encode {
    my ($int) = @_;

    my @bytes;
    while ($int > 0) {
	my $byte = 0;
	for (my $mask = 64; $mask > 0; $mask = $mask >> 1) {
	    $byte += $mask if ($mask & $int);
	}
	unshift (@bytes, $byte);
	$int = $int >> 7;
    }

    $bytes[0] += 128;

    for (my $i = 0; $i < scalar(@bytes); $i++) { 
	$bytes[$i] = chr ($bytes[$i]);
    }

    return \@bytes;
}

sub decode {
    my ($bytes) = @_;

    my $num;
    my @rets;
    foreach my $byte (@$bytes) {
	my $buf = $byte;
	if ($buf & 128) {
	    push (@rets, $num) if (defined $num);
	    $num = 0;
	}

	$num = $num << 7;
	for (my $mask = 64; $mask > 0; $mask = $mask >> 1) {
	    $num += $mask if ($mask & $buf);
	}
    }
    push (@rets, $num) if (defined $num);

    return \@rets;
}

1;
