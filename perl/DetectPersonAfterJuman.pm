package DetectPersonAfterJuman;

# $Id$

# Jumanの解析結果から人名を新たにみつける(人名のあとにつづく一文字漢字に着目)

use strict;
use utf8;

my @YOBIKAKE = qw/さん 君 くん 様 さま 殿 氏 ちゃん/; # knp/rule/mrph_basic.ruleより借用
my @THIRD_HAN_LIST = qw/子 郎 美 夫 雄 男 代 助 香 恵 里 江 衛 利 奈 志 合 介/; # 名の3文字目のリスト

sub new {
    my ($this, $opt) = @_;

    $this = { opt => $opt };

    foreach my $yobikake (@YOBIKAKE) {
	$this->{YOBIKAKE}{$yobikake} = 1;
	# 呼掛のうちの漢字だけ(一文字)
	$this->{YOBIKAKE_HAN}{$yobikake} = 1 if $yobikake =~ /^\p{Han}$/;
    }

    foreach my $han (@THIRD_HAN_LIST) {
	$this->{THIRD_HAN}{$han} = 1;
    }

    bless $this;

    return $this;
}

sub DESTROY {
    my ($this) = @_;
}

# 人名を検出する
sub DetectPerson {
    my ($this, $result) = @_;

    my @mrph = $result->mrph;

    for (my $i = 0; $i < @mrph; $i++) {
	# 「日本人名:」が意味情報についている場合は姓の場合のみ使う
	if ($mrph[$i]->bunrui eq '人名' && ($mrph[$i]->imis =~ /日本人名/ && $mrph[$i]->imis =~ /日本人名:姓/)) {
	    next if ! defined $mrph[$i + 1] || ! defined $mrph[$i + 2];

	    # 渡辺 美 智 雄
	    # 漢字の3文字目がリストにあるかチェック
	    if (defined $mrph[$i + 3] && $this->CheckOneHan($mrph[$i + 1]) && $this->CheckOneHan($mrph[$i + 2]) && $this->CheckOneHan($mrph[$i + 3], {check_third_han => 1}) && $this->CheckEndCondition($mrph[$i + 4])) {
		print STDERR $mrph[$i]->midasi, ' ',  $mrph[$i + 1]->midasi, ' ', $mrph[$i + 2]->midasi, ' ', $mrph[$i + 3]->midasi, "\n" if $this->{opt}{debug};

		# Featureを追加
		$this->PushImisMrphs($mrph[$i + 1], $mrph[$i + 2], $mrph[$i + 3]);
	    }
	    # 村山 富 市
	    # ただし、「羽田 孜 氏」をのぞくために、漢字の呼掛を除く
	    elsif ($this->CheckOneHan($mrph[$i + 1]) && $this->CheckOneHan($mrph[$i + 2]) && $this->CheckEndCondition($mrph[$i + 3])) {
		print STDERR $mrph[$i]->midasi, ' ',  $mrph[$i + 1]->midasi, ' ', $mrph[$i + 2]->midasi, "\n" if $this->{opt}{debug};

		# Featureを追加
		$this->PushImisMrphs($mrph[$i + 1], $mrph[$i + 2]);
	    }
	}
    }
}

# (人名) (漢字一文字) (漢字一文字)の次の形態素が条件を満たすかどうかをチェック
# - 助詞
# - 特殊
# - 接尾辞(「ら」など)
# - 呼掛
# 漢字2文字以上の語
sub CheckEndCondition {
    my ($this, $mrph) = @_;

    return 1 unless defined $mrph;

    if ($mrph->hinsi =~ /^(?:助詞|特殊|接尾辞)$/ || defined $this->{YOBIKAKE}{$mrph->midasi} || $mrph->midasi =~ /\p{Han}{2,}/) {
	return 1;
    }
    else {
	return 0;
    }
}

# 漢字一文字をチェック
# ただし、呼掛の漢字(氏など)、接尾辞(「大垣市内」の「市」など)、地名/組織名末尾(「福山西署」の「署」)を除く
# optionのcheck_third_hanがきたら、THIRD_HANのリストにあるかチェック
sub CheckOneHan {
    my ($this, $mrph, $option) = @_;

    if ($mrph->midasi =~ /^\p{Han}$/ && ! defined $this->{YOBIKAKE_HAN}{$mrph->midasi} && $mrph->hinsi !~ /^(?:接尾辞|接頭辞)$/ && $mrph->imis !~ /(?:地名末尾|組織名末尾)/) {
	if ($option->{check_third_han}) {
	    if (defined $this->{THIRD_HAN}{$mrph->midasi}) {
		return 1;
	    }
	    else {
		return 0;
	    }
	}
	else {
	    return 1;
	}
    }
    else {
	return 0;
    }
}

# 意味情報を追加
sub PushImisMrphs {
    my ($this, @mrphs) = @_;

    my $imi = '漢字一字人名疑';

    # 同形にも追加
    foreach my $mrph (@mrphs) {
	$mrph->push_imis($imi);

	for my $doukei ($mrph->doukei()) {
	    $doukei->push_imis($imi);
	}
    }
}

1;
