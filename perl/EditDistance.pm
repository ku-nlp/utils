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
use Dumpvalue;
binmode STDOUT, ":utf-8";

my @KatakanaDB = ('アイウエオァィゥェォ', 'カキクケコガギグゲゴヵヶ', 'サシスセソザジズゼゾ', 'タチツテトダヂヅデドッ', 'ナニヌネノ',  
		  'ハヒフヘホバビブベボパピプペポヴ', 'マミムメモ', 'ヤユヨャュョ', 'ラリルレロ',  'ワヰヲヱンヮ');
my $KatakanaKomoji = 'ァィゥェォヵヶャュョッーヶヵヮ';
my $KatakanaRep2 = 'ァィゥェォヵヶャュョッヶヵヮ';

sub new {
    my ($this, $option) = @_;

    $this = {};
    bless $this;

    $this->{DEL}{default} = 1;
    $this->{INS}{default} = 1;
    $this->{REP}{default} = 1.5;

    $this->{DEL}{default} = $option->{del_penalty} if (defined $option->{del_penalty});
    $this->{INS}{default} = $option->{ins_penalty} if (defined $option->{ins_penalty});
    $this->{REP}{default} = $option->{rep_penalty} if (defined $option->{rep_penalty});

    # ペナルティー
    if (defined $option->{penalty}) {
	open(IN, "<:utf8", $option->{penalty});
	my $max = 0;
	while (<IN>) {
	    chomp;
	    my ($score, $str) = split(/\t/);
	    my ($func, $pre, $body, $post) = split(/:/, $str);
	    $this->{$func}{"$pre:$body:$post"} += $score;
	    $this->{$func}{":$body:$post"} += $score/2;
	    $this->{$func}{"$pre:$body:"} += $score/2;
	    $this->{$func}{":$body:"} += $score/5;
	    if ($func eq "INS") {
		$this->{DEL}{"$pre:$body:$post"} += $score;
		$this->{DEL}{":$body:$post"} += $score/2;
		$this->{DEL}{"$pre:$body:"} += $score/2;
		$this->{DEL}{":$body:"} += $score/5;
	    } elsif ($func eq "REP") {
		my ($c1, $c2) = split("", $body);
		my $body2 = "$c2$c1";
		$this->{$func}{"$pre:$body2:$post"} += $score;
		$this->{$func}{":$body2:$post"} += $score/2;
		$this->{$func}{"$pre:$body2:"} += $score/2;
		$this->{$func}{":$body2:"} += $score/5;
	    }
	    $max = $score if ($max < $score);
	}
	close IN;
	foreach my $func (keys %{$this}) {
	    next unless ($func eq "INS" || $func eq "REP" || $func eq "DEL");
	    foreach my $str (keys %{$this->{$func}}) {
		$this->{$func}{$str} = 1 - ($this->{$func}{$str} / $max);
		if ($this->{$func}{$str} <= 0.01) {
		    $this->{$func}{$str} = 0.01;
		}
	    }
	}
    }

    return $this;
}

sub calc {
    my $this = shift;
    my ($str1, $str2, $option) = @_;

    my @str1 = split (//, $str1);
    my @str2 = split (//, $str2);

    my $table;
    $table->[0][0]{score} = 0;

    # 表の最上段を初期化
    for (my $j = 1; $j <= @str2; $j++) {
	my $pre = $j == 1 ? "*" : $str2[$j-2];
	my $body = $str2[$j-1];
	my $post = $str1[0];
	$table->[0][$j]{score} = $table->[0][$j-1]{score} + $this->get_score("INS", $pre, $body, $post);
	$table->[0][$j]{path} = "0:1";
    }
    
    for (my $i = 1; $i <= @str1; $i++) {
	for (my $j = 0; $j <= @str2; $j++) {
	    my $pre = $j == 0 ? "*" : $str2[$j-1];
	    my $body = $str1[$i-1];
	    my $post = $i == @str1 ? "*" : $str1[$i];
	    # 1文字削除
	    my $min_score = $table->[$i-1][$j]{score} + $this->get_score("DEL", $pre, $body, $post);
	    my $min_path = "1:0";

	    if ($j > 0) {
		$body = "$str1[$i-1]$str2[$j-1]";
		my $score = $this->get_score("REP", $pre, $body, $post);
		# 1vs1置換
		if ($str1[$i-1] eq $str2[$j-1] && $table->[$i-1][$j-1]{score} <= $min_score) {
		    $min_score = $table->[$i-1][$j-1]{score};
		    $min_path = "1:1:*";
		} else {
		    if ($table->[$i-1][$j-1]{score} + $score <= $min_score) {
			$min_score = $table->[$i-1][$j-1]{score} + $score;
			$min_path = "1:1";
		    }
		}

		$pre = $j == 1 ? "*" : $str2[$j-2];
		$body = $str2[$j-1];
		$score = $this->get_score("INS", $pre, $body, $post);
		# 1文字挿入
		if ($table->[$i][$j-1]{score} + $score <= $min_score) {
		    $min_score = $table->[$i][$j-1]{score} + $score;
		    $min_path = "0:1";
		}
	    }
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

    # 結果のトレース
    my $tmp1 = $#str1 + 1;
    my $tmp2 = $#str2 + 1;
    my $path;
    while ($tmp1 || $tmp2) {
	$path = "$table->[$tmp1][$tmp2]{path}/$path";
	my ($i_step, $j_step) = split(/:/, $table->[$tmp1][$tmp2]{path});
	$tmp1 -= $i_step;
	$tmp2 -= $j_step;
    }
    $path =~ s/\/$//;

    return ($table->[$#str1+1][$#str2+1]{score}, $path);
}


sub get_score {
    my $this = shift;
    my ($func, $pre, $body, $post) = @_;

    if (defined $this->{$func}{"$pre:$body:$post"}) {
	return $this->{$func}{default} * $this->{$func}{"$pre:$body:$post"};
    }
    elsif (defined $this->{$func}{":$body:$post"}) {
	return $this->{$func}{default} * $this->{$func}{":$body:$post"};
    }
    elsif (defined $this->{$func}{"$pre:$body:"}) {
	return $this->{$func}{default} * $this->{$func}{"$pre:$body:"};
    }
    elsif (defined $this->{$func}{":$body:"}) {
	return $this->{$func}{default} * $this->{$func}{":$body:"};
    }
    else {
	return $this->{$func}{default};
    }
}
