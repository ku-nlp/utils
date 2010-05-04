#!/usr/bin/env perl

# $Id$

# echo '�ѥ��ˡ��ˤμ���ˤ�붸���' | juman | perl -I../perl text_match_trie.pl -dbname /somewhere/wikipedia_entry_trie.i686.db -usejuman

use strict;
use encoding 'euc-jp';
use Juman;
use Trie;
use Getopt::Long;

my (%opt);
GetOptions(\%opt, 'dbname=s', 'usejuman', 'userepname', 'noskip');

unless ($opt{dbname}) {
    print STDERR "Please specify dbname!!\n";
    exit;
}

my $trie = new Trie(\%opt);
$trie->RetrieveDB($opt{dbname});

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
	print $trie->DetectString(\@mrphs, undef, { output_juman => 1 });
	undef $buf; 
    }
}
