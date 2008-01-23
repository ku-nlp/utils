package DetectPersonAfterJuman;

# $Id$

# Jumanの解析結果から人名を新たにみつける(人名のあとにつづく一文字漢字に着目)

use strict;
use utf8;

my @YOBIKAKE = qw/さん 君 くん 様 さま 殿 氏 ちゃん/; # knp/rule/mrph_basic.ruleより借用
my @THIRD_HAN_LIST = qw/子 郎 美 夫 雄 男 代 助 香 恵 里 江 衛 利 奈 志 合 介/; # 名の3文字目のリスト
my @NG_SECOND_HAN = qw/相/; # 河野 外 相

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

    foreach my $han (@NG_SECOND_HAN) {
	$this->{NG_SECOND_HAN}{$han} = 1;
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
	if ($this->CheckHaveSei($mrph[$i])) {

	    # 渡辺 美 智 雄
	    # 漢字の3文字目がリストにあるかチェック
	    if (defined $mrph[$i + 3] && $this->CheckOneHan($mrph[$i + 1]) && $this->CheckOneHan($mrph[$i + 2]) && $this->CheckOneHan($mrph[$i + 3], {check_third_han => 1}) && $this->CheckEndCondition($mrph[$i + 4])) {
		print STDERR $mrph[$i]->midasi, ' ',  $mrph[$i + 1]->midasi, ' ', $mrph[$i + 2]->midasi, ' ', $mrph[$i + 3]->midasi, "\n" if $this->{opt}{debug};

		$this->PrintMrph($mrph[$i]);

		$this->ConnetOneHans($mrph[$i + 1], $mrph[$i + 2], $mrph[$i + 3]);
		$i += 3;
		next;
	    }
	    # 村山 富 市
	    # ただし、「羽田 孜 氏」をのぞくために、漢字の呼掛を除く
	    elsif ($this->CheckOneHan($mrph[$i + 1]) && $this->CheckOneHan($mrph[$i + 2], {check_ng_second_han => 1}) && $this->CheckEndCondition($mrph[$i + 3])) {
		print STDERR $mrph[$i]->midasi, ' ',  $mrph[$i + 1]->midasi, ' ', $mrph[$i + 2]->midasi, "\n" if $this->{opt}{debug};

		$this->PrintMrph($mrph[$i]);

		$this->ConnetOneHans($mrph[$i + 1], $mrph[$i + 2]);

		$i += 2;
		next;
	    }
	}

	$this->PrintMrph($mrph[$i]);
    }

    print "EOS\n";
}

# 「姓」があるかチェック
# 「日本人名:」が意味情報についている場合は姓の場合のみ使う
sub CheckHaveSei {
    my ($this, $mrph) = @_;

    return 1 if &_checkhavesei($mrph);

    for my $doukei ($mrph->doukei()) {
	return 1 if &_checkhavesei($doukei);
    }
    return 0;
}

sub _checkhavesei {
    my ($mrph) = @_;

    if ($mrph->bunrui eq '人名' && ($mrph->imis =~ /日本人名/ && $mrph->imis =~ /日本人名:姓/)) {
	return 1;
    }
    else {
	return 0;
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

    return 0 if ! defined $mrph;

    if ($mrph->midasi =~ /^\p{Han}$/ && ! defined $this->{YOBIKAKE_HAN}{$mrph->midasi} && $mrph->hinsi !~ /^(?:接尾辞|接頭辞)$/ && $mrph->imis !~ /(?:地名末尾|組織名末尾)/) {
	if ($option->{check_third_han}) {
	    if (defined $this->{THIRD_HAN}{$mrph->midasi}) {
		return 1;
	    }
	    else {
		return 0;
	    }
	}
	# 河野 外 相
	elsif ($option->{check_ng_second_han}) {
	    if (defined $this->{NG_SECOND_HAN}{$mrph->midasi}) {
		return 0;
	    }
	    else {
		return 1;
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

# 形態素を出力する(同形も)
sub PrintMrph {
    my ($this, $mrph) = @_;

    print $mrph->spec;
    for my $doukei ($mrph->doukei()) {
	print '@ ', $doukei->spec;
    }
}

# 漢字一字を連結
sub ConnetOneHans {
    my ($this, @mrphs) = @_;

    my ($midasi, $yomi, $genkei);

    # 単純に連結する
    # 富 とみ 富 名詞 6 普通名詞 1 * 0 * 0 "漢字読み:訓 カテゴリ:人工物-金銭 代表表記:富/とみ"
    # 市 し 市 名詞 6 普通名詞 1 * 0 * 0 "漢字読み:音 住所末尾 カテゴリ:組織・団体:場所-その他 ドメイン:政治 代表表記:市/し"
    # ↓
    # 富市 とみし 富市 名詞 6 人名 5 * 0 * 0 "漢字一文字人名疑連結"

    foreach my $mrph (@mrphs) {
	$midasi .= $mrph->midasi;
	$yomi .= $mrph->yomi;
	$genkei .= $mrph->genkei;
    }
    print qq($midasi $yomi $genkei 名詞 6 人名 5 * 0 * 0 "漢字一文字人名疑連結"\n);
}

1;
