#!/usr/bin/env perl

# $Id$

# usage: perl -I../perl test-mrphseqmatch.pl -rule_file /somewhere/rule.txt (マッチさせたい文)

# ruleファイルの書式はperl/MrphSeqMatch.pmの関数read_ruleの直前を参照

use strict;
use utf8;
binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
binmode DB::OUT, ':encoding(utf8)';
use Encode;
use Getopt::Long;
use KNP;
use MrphSeqMatch;

my (%opt);
GetOptions(\%opt, 'rule_file=s', 'debug', 'help');

my $sentence = decode('utf-8', $ARGV[0]);

my $mrphseqmatch = new MrphSeqMatch($opt{rule_file}, \%opt);
my $knp = new KNP(-Option => '-tab -dpnd');

my $result = $knp->parse($sentence);
my $flag = $mrphseqmatch->MrphSeqMatch($result);

# 全体マッチの場合のみ
if ($flag) {
    print "Match!\n";
}
print $result->all_dynamic;
