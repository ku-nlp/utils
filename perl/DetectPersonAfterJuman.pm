package DetectPersonAfterJuman;

# $Id$

# Jumanの解析結果から人名を新たにみつける

# 1. 人名姓＋漢字一文字＋漢字一文字 => 最後の二文字を人名に
# 2. 人名姓＋漢字一文字＋漢字一文字＋漢字一文字(雄, 郎..) => 最後の三文字を人名に
# 3. 漢字一文字＋漢字一文字＋人名末尾 => 最初の二文字を人名に

use strict;
use utf8;

my @YOBIKAKE = qw/さん 君 くん 様 さま 殿 氏 ちゃん/; # knp/rule/mrph_basic.ruleより借用
my @THIRD_HAN_LIST = qw/子 郎 美 夫 雄 男 代 助 香 恵 里 江 衛 利 奈 志 合 介/; # 名の3文字目のリスト
my @NG_HAN_TYPE1 = qw/相/; # 河野 外 「相」
my @NG_HAN_TYPE2 = qw/王/; # 六 冠 「王」
my @NG_HAN_TYPE3 = qw/駐/; # 「駐」 日 大使

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

    foreach my $han (@NG_HAN_TYPE1) {
	$this->{NG_HAN_TYPE1}{$han} = 1;
    }

    foreach my $han (@NG_HAN_TYPE2) {
	$this->{NG_HAN_TYPE2}{$han} = 1;
    }

    foreach my $han (@NG_HAN_TYPE3) {
	$this->{NG_HAN_TYPE3}{$han} = 1;
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

    my (@result, @already_checked);

    for (my $i = 0; $i < @mrph; $i++) {
	# 「日本人名:」が意味情報についている場合は姓の場合のみ使う
	if ($this->CheckHaveSei($mrph[$i])) {

	    # 渡辺 美 智 雄
	    # 漢字の3文字目がリストにあるかチェック
	    if (defined $mrph[$i + 3] && $this->CheckOneHan($mrph[$i + 1], {no_matsubi => 1}) && $this->CheckOneHan($mrph[$i + 2], {no_matsubi => 1}) && $this->CheckOneHan($mrph[$i + 3], {check_third_han => 1}) && $this->CheckEndCondition($mrph[$i + 4])) {
		print STDERR $mrph[$i]->midasi, ' ',  $mrph[$i + 1]->midasi, ' ', $mrph[$i + 2]->midasi, ' ', $mrph[$i + 3]->midasi, "\n" if $this->{opt}{debug};

		# 結果の保持
		$result[$i]{person_name} = 'post'; # 自分より後ろに漢字一文字の列がある
		$result[$i]{one_han_list} = [ $i + 1, $i + 2, $i + 3 ];

		$already_checked[$i] = 1; $already_checked[$i + 1] = 1; $already_checked[$i + 2] = 1; $already_checked[$i + 3] = 1;

		$i += 3;
		next;
	    }
	    # 村山 富 市
	    # ただし、「羽田 孜 氏」をのぞくために、漢字の呼掛を除く
	    elsif ($this->CheckOneHan($mrph[$i + 1], {no_matsubi => 1}) && $this->CheckOneHan($mrph[$i + 2], {no_matsubi => 1, check_ng_second_han => 1}) && $this->CheckEndCondition($mrph[$i + 3])) {
		print STDERR $mrph[$i]->midasi, ' ',  $mrph[$i + 1]->midasi, ' ', $mrph[$i + 2]->midasi, "\n" if $this->{opt}{debug};

		# 結果の保持
		$result[$i]{person_name} = 'post';
		$result[$i]{one_han_list} = [ $i + 1, $i + 2 ];

		$already_checked[$i] = 1; $already_checked[$i + 1] = 1; $already_checked[$i + 2] = 1;
		$i += 2;
		next;
	    }
	}
	# 漢字一文字＋漢字一文字＋人名末尾 => 最初の二文字を人名
	# 例: 糸川先生
	# 「加藤 輝 美 社長」のように上記の処理で「輝美」となった場合はこの処理を行なわない
	elsif ($i >= 2 && $mrph[$i]->imis =~ /人名末尾/ && ! defined $this->{NG_HAN_TYPE2}{$mrph[$i]->midasi} && ! $already_checked[$i - 1] && ! $already_checked[$i - 2] && $this->CheckEndCondition($mrph[$i - 3])) {
	    if ($this->CheckOneHan($mrph[$i - 1]) && $this->CheckOneHan($mrph[$i - 2], {check_ng_type3 => 1})) {
		print STDERR $mrph[$i - 2]->midasi, '-',  $mrph[$i - 1]->midasi, '-', $mrph[$i]->midasi, "\n" if $this->{opt}{debug};

		# 結果の保持
		$result[$i]{person_name} = 'pre'; # 自分より前に漢字一文字の列がある
		$result[$i]{one_han_list} = [ $i - 2, $i - 1 ];
		$result[$i - 1]{pre_person} = 1;
		$result[$i - 2]{pre_person} = 1;
	    }
	}
    }

    $this->PrintResult(\@mrph, \@result);

}

# 結果の表示
sub PrintResult {
    my ($this, $mrph, $result) = @_;

    for (my $i = 0; $i < @{$mrph}; $i++) {
	next if defined $result->[$i]{pre_person};

	if (defined $result->[$i]{person_name}) {
	    my @connect_mrphs;
	    foreach my $j (@{$result->[$i]{one_han_list}}) {
		push @connect_mrphs, $mrph->[$j];
	    }

	    # 自分より前に一文字漢字列がある
	    if ($result->[$i]{person_name} eq 'pre') {
		$this->ConnetOneHans(@connect_mrphs);

		$this->PrintMrphWithDisambiguation($mrph->[$i]);
	    }
	    # 自分より後ろに一文字漢字列がある
	    else {
		$this->PrintMrphWithDisambiguation($mrph->[$i], { only_person => 1 });

		$this->ConnetOneHans(@connect_mrphs);

		$i += scalar (@connect_mrphs);
	    }
	}
	else {
	    $this->PrintMrph($mrph->[$i]);
	}
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

    if ($mrph->midasi =~ /^\p{Han}$/ && ! defined $this->{YOBIKAKE_HAN}{$mrph->midasi} && $mrph->hinsi !~ /^(?:接尾辞|接頭辞)$/ && (($option->{no_matsubi} && $mrph->imis !~ /(?:地名末尾|組織名末尾)/) || ! $option->{no_matsubi})) {
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
	    if (defined $this->{NG_HAN_TYPE1}{$mrph->midasi}) {
		return 0;
	    }
	    else {
		return 1;
	    }
	}
	# 駐日大使
	elsif ($option->{check_ng_type3}) {
	    if (defined $this->{NG_HAN_TYPE3}{$mrph->midasi}) {
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

# 人名と普通名詞などの曖昧性がある場合に、人名のみにする
# 野原 のはら 野原 名詞 6 普通名詞 1 * 0 * 0 "カテゴリ:場所-自然 代表表記:野原/のはら"
# @ 野原 のはら 野原 名詞 6 人名 5 * 0 * 0 "日本人名:姓:742:0.00022"
# ↓
# 野原 のはら 野原 名詞 6 人名 5 * 0 * 0 "日本人名:姓:742:0.00022"
sub PrintMrphWithDisambiguation {
    my ($this, $mrph, $option) = @_;

    my $output_count = 0;

    if (($option->{only_person} && $mrph->bunrui eq '人名') || ! $option->{only_person}) {
	print $mrph->spec;
	$output_count++;
    }
    for my $doukei ($mrph->doukei()) {
	if (($option->{only_person} && $doukei->bunrui eq '人名') || ! $option->{only_person}) {
	    if ($output_count) {
		print '@ ';
	    }
	    print $doukei->spec;
	    $output_count++;
	}
    }
    if ($output_count == 0) {
	print STDERR "Error! in PrintMrphWithDisambiguation\n";
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
