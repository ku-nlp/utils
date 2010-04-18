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

    my $n;
    my @rets;
    foreach my $byte (@$bytes) {
	if ($byte & 128) {
	    push (@rets, 128 * $n + ($byte - 128));
	    $n = 0;
	} else {
	    $n = 128 * $n + $byte;
	}
    }

    return \@rets;
}

1;
