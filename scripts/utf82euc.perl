#!/usr/bin/env perl

# $Id$

# Input:  utf8
# Output: euc-jp (2byte code)

use Encode;
use strict;
use Utf82Euc;

my $utf82euc = new Utf82Euc;

while (<STDIN>) {
    my $buf = decode('utf8', $_);
    $buf = $utf82euc->Conv3bytecode_to_geta($buf);

    print $buf;
}
