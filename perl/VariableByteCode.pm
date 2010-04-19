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
    while (1) {
	unshift (@bytes, ($int % 128));
	last if ($int < 128);
	$int = int($int/128);
    }
    $bytes[-1] += 128;

    for (my $i = 0; $i < scalar(@bytes); $i++) {
	$bytes[$i] = pack('C', $bytes[$i]);
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
