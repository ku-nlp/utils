#! /usr/bin/env perl

# $Id$

# test script for TransLiterate
#
# Usage:
#     perl -I../perl ./test-TransLiterate.pl
# とした後、標準入力から
#     カタカナ列 英単語列
# を入力
#
# 結果の1行目の数字が類似度で、2行目の英字列はアルファベット訳
#
# perl -I../perl ./test-TransLiterate.pl
# セカンドライフ second life
# 0.766666666666667
# sekandoraifu

use strict;
use utf8;
use TransLiterate;

my $TransLiterate = new TransLiterate;

binmode(STDIN,  ':encoding(euc-jp)');
binmode(STDOUT, ':encoding(euc-jp)');

while ( <STDIN> ){
    my ($a, @b) = split;
    my $score = $TransLiterate->transliterate($a, join(" ", @b), "English");
    print "$score\n";
    my $transliteration = $TransLiterate->transliterateJ($a, "English");
    print "$transliteration\n";
}
