package CompoundNounExtractor;

# $Id$

# 複合名詞を抽出するPerlモジュール

# 使い方

# 最長のもののみ
# foreach my $bnst ($result->bnst) {
#   my $word = $cne->ExtractCompoundNounfromBnst($bnst, { longest => 1 });
#   print $word->{midasi}, "\n" if $word;
# }

# 複合名詞すべて
# foreach my $bnst ($result->bnst) {
#   my @words = $cne->ExtractCompoundNounfromBnst($bnst);

#   foreach my $tmp (@words) {
#     print $tmp->{midasi}, "\n";
#   }
# }

use strict;
use utf8;
use vars qw($MRPH_NUM_MAX $NG_CHAR);

$MRPH_NUM_MAX = 100; # 複合名詞中の形態素数の最大上限数

$NG_CHAR = '・|っ|ぁ|ぃ|ぅ|ぇ|ぉ|ゃ|ゅ|ょ|ー'; # 拗音、長音など

sub new {
    my ($this, $option) = @_;

    $this = {};

    $this->{opt} = $option;

    bless $this;

    return $this;
}

sub DESTROY {
    my ($this) = @_;

}

# 文節から複合名詞を抽出する
sub ExtractCompoundNounfromBnst {
    my ($this, $bnst, $option) = @_;

    my @word_list;
    # タグから固有表現を抽出
    my %ne_list;
    foreach my $tag ($bnst->tag) {
	if ($tag->fstring =~ /<NE:([^>]*)>/) {
	    my ($type, $ne) = split (/:/, $1);
	    $ne_list{$ne} = $type;
	}
    }

    my $outputted_flag = 0;
    # ループを回して複合名詞を探す。
    #
    # ex) 自然 言語 処理 と は、
    #          $j  $i
    my @mrph_list = $bnst->mrph;
    for (my $i = $#mrph_list; $i >= 0; $i--) {
	my $mrph = $mrph_list[$i];

	# 複合名詞の最後に来られない形態素
#	next if ($self->is_stopword ($mrph, 'suffix'));

	# stopword
#	next if ($self->is_stopword ($mrph));

	# ひらがな一文字
	next if $mrph->midasi =~ /^\p{Hiragana}$/;
	
#	# 固有名詞の途中で終るものは登録しない
#	next unless ($mrph->fstring =~ /<NE:[A-Z]*:(head|middle)>/);

#	# 一番最後が名詞でなければ次へ
	# <かな漢字>を条件に入れることにより、「東京都」の「都」が除かれなくなる
	next unless ($mrph->fstring =~ /<(?:名詞相当語|かな漢字|カタカナ)>/);

	# 形式名詞（もの, こと..)/副詞的名詞(よう, とき..)
	next if $mrph->bunrui =~ /(?:副詞的|形式)名詞/;

	# 一番最後が記号や数字なら次へ
	# 名詞相当語 かつ 記号 .. ●,《, ＠など
	# 名詞相当語 かつ 時間辞 .. 1960年代半ばの「代」など
	# 数字 .. もし入れると新聞記事やブログの日付が大量に混入?
	next if ($mrph->fstring =~ /<記号>|<数字>/);

	# 接頭辞で終ってはいけない
	# 「イースター島再来訪」から「イースター島再」を排除
	next if ($mrph->fstring =~ /<非?独立タグ接頭辞>/);

	# 非独立接尾辞はNG ただし<意味有>がついている(個、つ、県、化、性など)ならばOK
	next if $mrph->fstring =~ /<非独立タグ接尾辞>/ && $mrph->fstring !~ /<意味有>/;

	my $mrph_num = 0;
	my $midasi = '';
	my $repname = '';
	#　一番最後を固定してループ
	for (my $j = $i; $j >= 0; $j--) {

	    # 名詞か独立タグ接頭辞なら連結
	    #  <複合←>で捕捉したいもの 「・」「アルファベット一文字」「ドル」「グラム」「ｋｇ」など(たぶん)
	    #  <複合←>かつ<記号> .. ；＆など多数
	    # 独立タグ接頭辞 .. 旧、全、不など
	    # 非独立タグ接頭辞 .. 「お見舞い」の「お」などは入れない
	    # 問題点：「・」は、複合語の頭や最後にはきてほしくないが、
	    #         「ドル」は、最後ならばきても良い。
	    my $mrph2 = $mrph_list[$j];

#	    # 固有名詞の途中から始まるものは登録しない
#	    next unless ($mrph->fstring =~ /<NE:[A-Z]*:(middle|tail)>/);

	    last unless ($mrph2->fstring =~ /<名詞相当語>|<漢字>|<独立タグ接頭辞>|<複合←>/);

	    last if $mrph2->fstring =~ /<記号>/ || $mrph2->bunrui =~ /(?:副詞的|形式)名詞/;

	    $mrph_num++;

	    $midasi = $mrph2->midasi . $midasi;
	    my $tmp = $mrph2->repname ();
	    $repname = (($tmp)? $tmp : $mrph2->midasi) . (($repname)?  '+' .  $repname : '');

	    last if ($mrph_num > $MRPH_NUM_MAX);

	    # 一語ばかりからなる複合語は大抵ごみ (文字化けなど)
	    last if ($mrph_num >= 5 && length ($midasi) <= $mrph_num);

	    # 複合語の途中に来ても良いが、先頭に来るのは変なものを排除する条件群
	    if ($mrph2->fstring =~ /<名詞相当語>|<漢字>|<独立タグ接頭辞>/
		&& $mrph2->hinsi ne '接尾辞' # 「-性海棉状脳症」などを除く
#		&& !$self->is_stopword ($mrph2, 'prefix')
#		&& $mrph2->fstring !~ /末尾/ && # 人名末尾, 組織名末尾などで終るものを除く
		&& $mrph2->midasi !~ /^(?:$NG_CHAR)/) {
#		if ($ne_list{$midasi}) {
#		    push @word_list, [$midasi, $repname];
#		} else {
#		    push @word_list, [$midasi, $repname, $ne_list{$midasi}];
#		}
		push @word_list, { midasi => $midasi, repname => $repname, mrphnum => $mrph_num };

		print "register $midasi\n" if ($this->{option}{debug});
		$outputted_flag = 1;
	    }
	}

	# 最長
	if ($option->{longest} && $outputted_flag) {
	    return $word_list[-1];
	}
    }
    return wantarray ? @word_list : $word_list[-1];
}

1;
