package EditDistance;

######################################################################################
# 二つの文字列間の編集距離を計算するモジュール
# 
# 黒橋研究室 博士1年  中澤 敏明
# nakazawa@nlp.kuee.kyoto-u.ac.jp
######################################################################################

use strict;
use utf8;

my $del_penalty = 1;
my $ins_penalty = 1;
my $rep_penalty = 1.5;

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
    my ($this, $str1, $str2) = @_;

    my @str1 = split (//, $str1);
    my @str2 = split (//, $str2);

    my $table;
    $table->[0][0]{score} = 0;

    # 表の最上段を初期化
    for (my $j = 1; $j <= @str2; $j++) {
	$table->[0][$j]{score} += $ins_penalty;
    }
    
    for (my $i = 1; $i <= @str1; $i++) {
	for (my $j = 0; $j <= @str2; $j++) {
	    # 1文字削除
	    my $min_score = $table->[$i-1][$j]{score} + $del_penalty;
	    my $min_path =  "1:0";

	    # 1文字挿入
	    if ($j > 0 && $table->[$i][$j-1]{score} + $ins_penalty <= $min_score) {
		$min_score = $table->[$i][$j-1]{score} + $ins_penalty;
		$min_path = "0:1";
	    }

	    # 1vs1置換
	    if ($j > 0) {
		if ($str1[$i-1] eq $str2[$j-1] && $table->[$i-1][$j-1]{score} <= $min_score) {
		    $min_score = $table->[$i-1][$j-1]{score};
		    $min_path = "1:1";
		} else {
		    if ($table->[$i-1][$j-1]{score} + $rep_penalty <= $min_score) {
			$min_score = $table->[$i-1][$j-1]{score} + $rep_penalty;
			$min_path = "1:1";
		    }
		}
		
	    }
	    $table->[$i][$j]{score} = $min_score;
	    $table->[$i][$j]{path} = $min_path;
	}
    }
    return $table->[$#str1+1][$#str2+1]{score};
}
