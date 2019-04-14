package MrphSeqMatch;

# $Id$

# 形態素パターンにマッチするかを調べるモジュール

use utf8;
use strict;
use Juman;
use KNP;

our %CHARTYPE = ('ひらがな' => 'InHiragana', 'カタカナ' => 'InKatakana', '漢字' => 'Han', '英数字' => 'Latin');

sub new {
    my ($this, $rule_file, $opt) = @_;

    $this = {
	rules => &read_rule($rule_file),
	opt => $opt
    };

    bless $this;
    return $this;
}

sub DESTROY {
    my ($this) = @_;
}

# 形態素列がマッチするか調べる
sub MrphSeqMatch {
    my ($this, $result) = @_;

    # Mrph番号からTag番号を得るなど
    my ($m2b, $m2t, $t2b);
    if (!defined $this->{opt}{juman}) {
	$m2b = $this->GetMnum2Bnum($result); 
	$m2t = $this->GetMnum2Tnum($result);
	$t2b = $this->GetTnum2Bnum($result);
    }

    my ($flag, $flag_s,$split_num);
    my $rule_num = scalar @{$this->{rules}};
    my $mrph_num = scalar($result->mrph);

    for (my $i = 0; $i < $rule_num; $i++) {
	my $rule = $this->{rules}[$i];
	for (my $j = $mrph_num - 1; $j >= 0; $j--) {
	    next if defined $rule->{whole_match} && $j != 0;

	    $flag = 1;
	    $flag_s = 1;
	    $split_num = 0;

	    my $pattern_num = scalar @{$rule->{pattern}};
	    for (my $k = 0; $k < $pattern_num; $k++) {
		# マッチしない場合、flagを下げて次の形態素へ

		# sが最後についているパターンはそのパターンと前のパターンの間に
		# 任意のパターンの形態素が入ることを示す
		if ($rule->{pattern}[$k] =~ /s$/){
		    $flag_s = 0;
		}

		unless ($j + $k + $split_num < $mrph_num &&
			$this->MrphMatch($result, $rule->{pattern}[$k], $j +$k + $split_num, \$flag_s, $m2b, $m2t, $t2b)) {
		    $flag = 0;
		    last;
		}

		unless ($flag_s) {
		    $split_num++;
		    $k--;
		}
	    }
	    if ($flag && $flag_s
		&& ((defined $rule->{whole_match} && $j + $pattern_num == $mrph_num) || !defined $rule->{whole_match})) {

		if (defined $rule->{whole_match} || defined $rule->{no_add_feature}) {
		    return 1;
		}

		if (defined $rule->{mrph}) {
		    $this->AddMrphFeatureFromMnum($result, $j + $split_num + $rule->{mark_start}, $j + $split_num + $rule->{mark_end}, \@{$rule->{feature}});
		}
		elsif (defined $rule->{tag}) {
		    $this->AddTagFeatureFromMnum($result, $j + $split_num + $rule->{mark_start}, $j + $split_num + $rule->{mark_end}, \@{$rule->{feature}}, $m2t, defined $rule->{last} ? 1 : 0);
		}
		else {
		    $this->AddBnstFeatureFromMnum($result, $j + $split_num + $rule->{mark_start}, $j + $split_num + $rule->{mark_end}, \@{$rule->{feature}}, $m2b);
		}
	    }
	}
    }
}

# 指定形態素が指定パターンにマッチしたら1を返す
sub MrphMatch {
    my ($this, $result, $pat, $m_num, $split_flag, $m2b, $m2t, $t2b) = @_;
    my ($i, $neg_flag, $match_flag);

    $pat =~ s/s$//;

    # ^ と < を区切りにし，先頭，重複を削除
    $pat =~ s/\</ \</g;
    $pat =~ s/\^/ \^/g;
    $pat =~ s/^ \</\</g;
    $pat =~ s/^ \^/\^/g;
    $pat =~ s/\^ \</\^\</g;

    foreach $i (split(/ /, $pat)) {
	if ($i =~ s/\^//) {
	    $neg_flag = 1;
	} else {
	    $neg_flag = 0;
	}

	$match_flag = $this->CheckPatternTag($result, $i, $m_num, $m2b, $m2t);

	return 0 if ($match_flag eq $neg_flag && $$split_flag == 1);
	return 1 if ($match_flag eq $neg_flag && $$split_flag == 0);
    }

    $$split_flag = 1 unless $$split_flag;
    return 1;
}

# パターンと照合するかチェック
sub CheckPatternTag {
    my ($this, $result, $pat, $m_num, $m2b, $m2t) = @_;

    if ($pat =~ /^\<品詞:(.+)\>/) {
	my $pat_content = $1;
	return 1 if ($result->mrph)[$m_num]->hinsi =~ /^$pat_content$/;
    }
    elsif ($pat =~ /^\<原形:(.+)\>/) {
	my $pat_content = $1;
	return 1 if ($result->mrph)[$m_num]->genkei =~ /^$pat_content$/;
    }
    elsif ($pat =~ /^\<分類:(.+)\>/) {
	my $pat_content = $1;
	return 1 if ($result->mrph)[$m_num]->bunrui =~ /^$pat_content$/;
    }
    elsif ($pat =~ /^\<活用:(.+)\>/) {
	my $pat_content = $1;
	return 1 if ($result->mrph)[$m_num]->katuyou2 =~ /^$pat_content$/;
    }
    elsif ($pat =~ /^\<字種:(.+)\>/) {
	my $pat_content = $1;
	return 1 if ($result->mrph)[$m_num]->midasi =~ /^\p{$CHARTYPE{$pat_content}}+$/;
    }
    elsif ($pat =~ /^\<長さ:(.+)\>/) {
	my $pat_content = $1;
	return 1 if length(($result->mrph)[$m_num]->midasi) eq $1;
    }
    elsif ($pat =~ /^\<F:(.+)\>/) {
	my $fpat = "<$1";
	return 1 if ($result->bnst)[$m2b->[$m_num]]->fstring =~ /$fpat(\:|\>)/;
    }
    elsif ($pat =~ /^\<T:(.+)\>/) {
	my $fpat = "<$1";
	return 1 if ($result->tag)[$m2t->[$m_num]]->fstring =~ /$fpat(\:|\>)/;
    }
    elsif ($pat =~ /^\<f:(.+)\>/) {
	my $fpat = "<$1";
	return 1 if ($result->mrph)[$m_num]->fstring =~ /$fpat(\:|\>)/;
    }
    # 係り受けのタイプ
    elsif ($pat =~ /^\<d:(.+)\>/) {
	return 1 if ($result->bnst)[$m2b->[$m_num]]->dpndtype eq $1;
    }
    elsif ($pat =~ /^\</) {
	print STDERR "Warning! $pat\n";
    }
    elsif ($pat eq '.') {
	return 1;
    }
    else {
	return 1 if $pat eq ($result->mrph)[$m_num]->midasi;
    }

    return 0;
}

# 文節のfeatureに追加
sub AddBnstFeatureFromMnum {
    my($this,$result, $mark_start, $mark_end, $feature_lst, $m2b) = @_;
    my ($i, $pre_bnum);

    $pre_bnum = -1;
    for ($i = $mark_start; $i <= $mark_end; $i++) {
	if ($pre_bnum != $m2b->[$i]) {
	    ($result->bnst)[$m2b->[$i]]->push_feature(@{$feature_lst});
	    $pre_bnum = $m2b->[$i];
	}
    }
}

# Tagのfeatureに追加
sub AddTagFeatureFromMnum {
    my($this,$result, $mark_start, $mark_end, $feature_lst, $m2t, $last) = @_;
    my ($i, $pre_tnum);

    $pre_tnum = -1;
    for ($i = $mark_start; $i <= $mark_end; $i++) {
	next if $last && $i ne $mark_end;
	if ($pre_tnum != $m2t->[$i]) {
	    ($result->tag)[$m2t->[$i]]->push_feature(@{$feature_lst});
	    $pre_tnum = $m2t->[$i];
	}
    }
}

# 形態素のfeatureに追加
sub AddMrphFeatureFromMnum {
    my($this, $result, $mark_start, $mark_end, $feature_lst) = @_;
    my ($i, $pre_tnum);

    for ($i = $mark_start; $i <= $mark_end; $i++) {
	($result->mrph)[$i]->push_feature(@{$feature_lst});
    }
}

# Morpheme番号からBnst番号を得る
sub GetMnum2Bnum {
    my ($this, $result) = @_;

    my @m2b;
    my $c = 0;
    my $bnst_num = scalar($result->bnst);
    for (my $i = 0; $i < $bnst_num; $i++) {
	my $mrph_num = scalar(($result->bnst)[$i]->mrph);
	for (my $j = 0; $j < $mrph_num; $j++) {
	    $m2b[$c] = $i;
	    $c++;
	}
    }
    return \@m2b;
}

# Morpheme番号からTag番号を得る
sub GetMnum2Tnum {
    my ($this, $result) = @_;

    my @m2t;
    my $c = 0;
    my $tag_num = scalar($result->tag);
    for (my $i = 0; $i < $tag_num; $i++) {
	my $mrph_num = scalar(($result->tag)[$i]->mrph);
	for (my $j = 0; $j < $mrph_num; $j++) {
	    $m2t[$c] = $i;
	    $c++;
	}
    }
    return \@m2t;
}

# Tag番号からBnst番号を得る
sub GetTnum2Bnum {
    my ($this, $result) = @_;

    my @t2b;
    my $c = 0;
    my $bnst_num = scalar($result->bnst);
    for (my $i = 0; $i < $bnst_num; $i++) {
	my $tag_num = scalar(($result->bnst)[$i]->tag);
	for (my $j = 0; $j < $tag_num; $j++) {
	    $t2b[$c] = $i;
	    $c++;
	}
    }
    return \@t2b;
}

# ルールファイルの読み込み
# 一行が1ルール
# ルールファイルには以下の2とおりがある
# 
# 1. 左辺がマッチしたら右辺の情報を付与
# 例: 「〜しており」にマッチすれば、(マッチした形態素に)「PositiveCand」というFeatureを付与
# <品詞:動詞><活用:タ系連用テ形> おり -> PositiveCand
#
# 2. 全体がマッチするかどうか
# 例: 「二人組」にマッチ
# <分類:数詞> <品詞:接尾辞> <品詞:(名詞|接尾辞)>

sub read_rule {
    my ($rule_file) = @_;

    my @rules;
    open(RULE, "<:encoding(utf-8)", $rule_file) || die;
    my $rule_num = 0;

    while ( <RULE> ) {
	chomp;
	my $line = $_;
	next if $line eq '' || $line =~ /^\#/;

	my ($pattern, $feature);
	if ($line =~ / \-\> /) {
	    ($pattern, $feature) = split(/ \-\> /, $line);

	    if ($feature eq 'NIL') {
		$rules[$rule_num]{no_add_feature} = 1; 
	    }
	    else {
		if ($feature =~ s/^T://) {
		    $rules[$rule_num]{tag} = 1;
		}
		else {
		    $rules[$rule_num]{mrph} = 1;
		}
		if ($feature =~ s/\@L$//) {
		    $rules[$rule_num]{last} = 1;
		}
		@{$rules[$rule_num]{feature}} = split(/ /, $feature);
	    }
	}
	else {
	    $pattern = $line;
	    $rules[$rule_num]{whole_match} = 1;
	}

	@{$rules[$rule_num]{pattern}} = split(/ /, $pattern);

	$rules[$rule_num]{mark_start} = -1;
	for (my $i = 0; $i < @{$rules[$rule_num]{pattern}}; $i++) {
	    if (@{$rules[$rule_num]{pattern}}[$i] =~ s/n$//) {
		;
	    } else {
		$rules[$rule_num]{mark_start} = $i if ($rules[$rule_num]{mark_start} == -1);
		$rules[$rule_num]{mark_end} = $i;
	    }
	}
	
	$rules[$rule_num]{line} = $line;
	$rule_num++;

    }
    close(RULE);

    return \@rules;
}

1;
