#!/usr/bin/env perl

######################################################################################
# Æó¤Ä¤ÎÊ¸»úÎó´Ö¤ÎÊÔ½¸µ÷Î¥¤ò·×»»¤¹¤ë¥×¥í¥°¥é¥à
# 
# ¹õ¶¶¸¦µæ¼¼ Çî»Î1Ç¯  Ãæß· ÉÒÌÀ
# nakazawa@nlp.kuee.kyoto-u.ac.jp
#
# Usage: perl -I../perl ./test-EditDistance.pl "¥á¥â¥ê¡¼" "¥á¥â¥ê"
#
######################################################################################

use strict;
use encoding 'euc-jp';
use EditDistance;
use Encode;

my $edit_distance = new EditDistance({del_penalty => 1,
				      ins_penalty => 1,
				      rep_penalty => 1.5,
				      penalty => $ARGV[2]});

my ($score, $path) = $edit_distance->calc(decode('euc-jp', $ARGV[0]), decode('euc-jp', $ARGV[1]), {debug => 1}), "\n";

print "Score: $score\nPath: $path\n";



