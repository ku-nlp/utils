#!/usr/bin/env perl

# $Id$

use strict;
use utf8;
use CDB_Writer;

my $cdb = new CDB_Writer("hoge.cdb", "hoge.cdb.keymap", 2.5 * 1024 * 1024 * 1024, 1000000);

while (<STDIN>) {
    chop($_);
    my($k, $v) = split(' ', $_);
    $cdb->add($k, $v);
}

$cdb->close();
