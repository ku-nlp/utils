#!/usr/bin/env perl

# $Id$

# usage: perl -I../perl make-trie-db.perl -dbname XXX.db -usejuman < text.txt

use strict;
use encoding 'euc-jp';
use Getopt::Long;
use Trie;

my (%opt);
GetOptions(\%opt, 'dbname=s', 'usejuman');

unless ($opt{dbname}) {
    print STDERR "Please specify dbname!!\n";
    exit;
}

my $trie = new Trie(\%opt);

# µşÀ®ÄÅÅÄ¾Â±Ø WP¾å°Ì¸ì:±Ø/¤¨¤­
while (<>) {
    chomp;

    my ($string, $info) = split(' ', $_);

    $trie->Add($string, $info);
}

$trie->MakeDB($opt{dbname});
