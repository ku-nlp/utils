package CheckStrangeMrph;

# $Id$

# あやしい形態素をチェックするモジュール

use utf8;
use strict;

use vars qw($Youon);

$Youon = 'っ|ぁ|ぃ|ぅ|ぇ|ぉ|ゃ|ゅ|ょ|ッ|ァ|ィ|ゥ|ェ|ォ|ャ|ュ|ョ|'; # 拗音

sub new {
    my ($this) = @_;

    $this = {};

    bless $this;

    return $this;
}

sub DESTROY {
    my ($this) = @_;
}

# あやしいひらがなをチェック
sub CheckStrangeHiragana {
    my ($this, $mrph, $mrph_pre, $mrph_post) = @_;

    if ($mrph->midasi =~ /^\p{Hiragana}+$/ && 
	((defined $mrph_pre && $this->_CheckStrangeHiragana($mrph_pre, 'pre')) || (defined $mrph_post && $this->_CheckStrangeHiragana($mrph_post, 'post')))) {
	return 1;
    }
    else {
	return 0;
    }
}

# あやしいひらがなかどうかチェック(内部関数)
sub _CheckStrangeHiragana {
    my ($this, $mrph, $type) = @_;

    # ひらがな/カタカナ一文字の未定義語 または ひらがな/カタカナで拗音のみ
    # 例: こなぃだ
    # 例: 楽しみだなッッ
    if (($mrph->midasi =~ /^[\p{Hiragana}\p{Katakana}]$/ && $mrph->hinsi eq '未定義語') ||
	$mrph->midasi =~ /^[\p{Hiragana}\p{Katakana}]+$/ && $mrph->midasi =~ /^(?:$Youon)+$/) {
	return 1;
    }
    # 後ろに動詞性接尾辞
    # 例: ぐるない
    elsif ($type eq 'post' && $mrph->bunrui eq '動詞性接尾辞') {
	return 1;
    }
    else {
	return 0;
    }
}

1;
