#!/usr/bin/env perl

######################################################################################
# ��Ĥ�ʸ����֤��Խ���Υ��׻�����ץ������
# 
# �������漼 ���1ǯ  ��߷ ����
# nakazawa@nlp.kuee.kyoto-u.ac.jp
#
# Usage: perl -I../perl ./test-EditDistance.pl "���꡼" "����"
#
######################################################################################

use strict;
use encoding 'euc-jp';
use EditDistance;
use Encode;

my $edit_distance = new EditDistance({del_penalty => 1,
				      ins_penalty => 1,
				      rep_penalty => 1.5});

print $edit_distance->calc(decode('euc-jp', $ARGV[0]), decode('euc-jp', $ARGV[1])), "\n";
