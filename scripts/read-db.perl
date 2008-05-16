#!/usr/bin/env perl

# $Id$

# usage: perl -I../perl read-db.perl -keymap /somewhere/test.keymap -key テスト
# データベースの名前はkeymap内に記述されている

use utf8;
use strict;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
use CDB_Reader;
use Encode;
use Getopt::Long;

my (%opt);
GetOptions(\%opt, 'keymap=s', 'key=s', 'numerical_key');

my $reader = new CDB_Reader($opt{keymap}, \%opt);

$opt{key} = decode('utf8', $opt{key});

my $value = $reader->get($opt{key});

print decode('utf8', $value), "\n";
