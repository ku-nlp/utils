#!/usr/bin/env perl

# $Id$

# usage: perl -I../perl make-db.perl --dbname /somewhere/test.cdb --keymapfile test.cdb.keymap < test.txt
# keymapfileはdbnameと同じディレクトリの下にできる

use strict;
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
use CDB_Writer;
use Getopt::Long;

my (%opt);
GetOptions(\%opt, 'dbname=s', 'keymapfile=s', 'limit_file_size=i', 'fetch=i', 'tab_delimiter');

$opt{limit_file_size} = 2.5 * 1024 * 1024 * 1024 unless $opt{limit_file_size};
$opt{fetch} = 1000000 unless $opt{fetch};

my $cdb = new CDB_Writer($opt{dbname}, $opt{keymapfile}, $opt{limit_file_size}, $opt{fetch});

while (<STDIN>) {
    chop($_);
    my ($k, $v);
    if ($opt{tab_delimiter}) {
	($k, $v) = split;
    }
    else {
	($k, $v) = split(' ', $_);
    }
    $cdb->add($k, $v);
}

$cdb->close();
