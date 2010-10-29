#!/usr/bin/env perl

# $Id$

# echo 'パガニーニの主題による狂詩曲' | juman | perl -I../perl text_match_trie.pl -dbname /somewhere/wikipedia_entry_trie.i686.db -usejuman

use strict;
use encoding 'euc-jp';
use Juman;
use Trie;
use Getopt::Long;

my (%opt);
GetOptions(\%opt, 'dbname=s', 'usejuman', 'userepname', 'skip', 'add_end_pos');

unless ($opt{dbname}) {
    print STDERR "Please specify dbname!!\n";
    exit;
}

my $trie = new Trie(\%opt);
$trie->RetrieveDB($opt{dbname});

my $detect_string_option = { output_juman => 1 };
$detect_string_option->{add_end_pos} = 1 if $opt{add_end_pos}; # マッチした形態素の一番後ろに情報を付与するオプション

my $buf;
while (<>) {
    if (/\# S-ID/) {
	print;
	next;
    }

    $buf .= $_;

    if (/EOS/) {
	my $result = new Juman::Result($buf);
	my @mrphs = $result->mrph;
	print $trie->DetectString(\@mrphs, undef, $detect_string_option);
	undef $buf; 
    }
}
