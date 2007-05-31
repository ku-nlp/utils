package EditDistance;

######################################################################################
# 二つの文字列間の編集距離を計算するモジュール
# 
# 黒橋研究室 博士1年  中澤 敏明
# nakazawa@nlp.kuee.kyoto-u.ac.jp
#
# 最短経路について
# 1:0   => 一文字削除
# 0:1   => 一文字挿入
# 1:1   => 一文字置換
# 1:1:* => 何もしない(同じ文字)
#
######################################################################################

use strict;
use utf8;

my $del_penalty = 1;
my $ins_penalty = 1;
my $rep_penalty = 1.5;

my @KatakanaDB = ('アイウエオァィゥェォ', 'カキクケコガギグゲゴヵヶ', 'サシスセソザジズゼゾ', 'タチツテトダヂヅデドッ', 'ナニヌネノ',  
		  'ハヒフヘホバビブベボパピプペポヴ', 'マミムメモ', 'ヤユヨャュョ', 'ラリルレロ',  'ワヰヲヱンヮ');
my $KatakanaKomoji = 'ァィゥェォヵヶャュョッーヶヵヮ';
my $KatakanaRep2 = 'ァィゥェォヵヶャュョッヶヵヮ';

sub new
{
    my ($this, $option) = @_;

    $del_penalty = $option->{del_penalty} if (defined $option->{del_penalty});
    $ins_penalty = $option->{ins_penalty} if (defined $option->{ins_penalty});
    $rep_penalty = $option->{rep_penalty} if (defined $option->{rep_penalty});

    $this = {};
    bless $this;
    return $this;
}

sub calc
{
    my ($this, $str1, $str2, $option) = @_;

    my @str1 = split (//, $str1);
    my @str2 = split (//, $str2);

    my $table;
    $table->[0][0]{score} = 0;

    # 表の最上段を初期化
    for (my $j = 1; $j <= @str2; $j++) {
	$table->[0][$j]{score} = $table->[0][$j-1]{score} + $ins_penalty;
	$table->[0][$j]{path} = "0:1";
    }
    
    for (my $i = 1; $i <= @str1; $i++) {
	for (my $j = 0; $j <= @str2; $j++) {
	    # 1文字削除
	    my $min_score = $table->[$i-1][$j]{score} + $del_penalty;
	    my $min_path = "1:0";

	    # 1文字挿入
	    if ($j > 0 && $table->[$i][$j-1]{score} + $ins_penalty <= $min_score) {
		$min_score = $table->[$i][$j-1]{score} + $ins_penalty;
		$min_path = "0:1";
	    }

	    # 1vs1置換
	    if ($j > 0) {
		if ($str1[$i-1] eq $str2[$j-1] && $table->[$i-1][$j-1]{score} <= $min_score) {
		    $min_score = $table->[$i-1][$j-1]{score};
		    $min_path = "1:1:*";
		} else {
		    if ($table->[$i-1][$j-1]{score} + $rep_penalty <= $min_score) {
			$min_score = $table->[$i-1][$j-1]{score} + $rep_penalty;
			$min_path = "1:1";
		    }
		}
	    }
	    print "$i $j: $min_score $min_path\n";
	    $table->[$i][$j]{score} = $min_score;
	    $table->[$i][$j]{path} = $min_path;
	}
    }

    # スコアテーブルを表示
    if ($option->{debug}) {
	for (my $i = 0; $i <= @str1; $i++) {
	    for (my $j = 0; $j <= @str2; $j++) {
		printf "%2.1f ", $table->[$i][$j]{score};
	    }
	    print "\n";
	}
    }
    print "@str1 @str2\n";
    # 結果のトレース
    my $tmp1 = $#str1 + 1;
    my $tmp2 = $#str2 + 1;
    my $path;
    while ($tmp1 || $tmp2) {
	print "$tmp1 $tmp2 $table->[$tmp1][$tmp2]{path}\n";
	$path = "$table->[$tmp1][$tmp2]{path}/$path";
	my ($i_step, $j_step) = split(/:/, $table->[$tmp1][$tmp2]{path});
	$tmp1 -= $i_step;
	$tmp2 -= $j_step;
    }

    return ($table->[$#str1+1][$#str2+1]{score}, $path);
}
