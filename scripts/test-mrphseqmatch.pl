#!/usr/bin/env perl

# $Id$

# usage: perl -I../perl test-mrphseqmatch.pl -rule_file /somewhere/rule.txt (�ޥå���������ʸ)

# rule�ե�����ν񼰤�perl/MrphSeqMatch.pm�δؿ�read_rule��ľ���򻲾�

use strict;
use encoding 'euc-jp';
binmode STDERR, ':encoding(euc-jp)';
binmode DB::OUT, ':encoding(euc-jp)';
use Encode;
use Getopt::Long;
use KNP;
use MrphSeqMatch;

my (%opt);
GetOptions(\%opt, 'rule_file=s', 'debug', 'help');

my $sentence = decode('euc-jp', $ARGV[0]);

my $mrphseqmatch = new MrphSeqMatch($opt{rule_file}, \%opt);
my $knp = new KNP(-Option => '-tab -dpnd');

my $result = $knp->parse($sentence);
my $flag = $mrphseqmatch->MrphSeqMatch($result);

if ($flag) {
    print "Match!\n";
}
print $result->all_dynamic;
