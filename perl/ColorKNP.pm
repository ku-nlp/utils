package ColorKNP;

# $Id$

# KNPの解析結果に色をつけるモジュール

use encoding 'euc-jp';
use Term::ANSIColor;
use strict;

sub new {
    my ($this, $feature_color, $opt) = @_;

    $this = {
	feature_color => $feature_color,
	opt => $opt
	};

    bless $this;
    return $this;
}

sub DESTORY {
    my ($this) = @_;
}

# 色をつける
sub AddColor {
    my ($this, $result) = @_;

    my $ret_string;

    if ($this->{opt}{mrph}) {
	foreach my $mrph ($result->mrph) {
	    my $string = $mrph->midasi;

	    # 形態素の場合は品詞も対象に
	    my $feature =  "<" . $mrph->hinsi . ">" . "<" . $mrph->bunrui . ">" . $mrph->fstring;
	    $ret_string .= $this->AddColortoString($string, $feature);
	}
    }
    elsif ($this->{opt}{tag}) {
	foreach my $tag ($result->tag) {
	    my $string;
	    foreach my $mrph ($tag->mrph) {
		$string .= $mrph->midasi;
	    }
	    $ret_string .= $this->AddColortoString($string, $tag->fstring);
	}
    }
    elsif ($this->{opt}{bnst}) {
	foreach my $bnst ($result->bnst) {
	    my $string;
	    foreach my $mrph ($bnst->mrph) {
		$string .= $mrph->midasi;
	    }
	    $ret_string .= $this->AddColortoString($string, $bnst->fstring);
	}
    }

    return $ret_string;
}

# $stringに色をつける
sub AddColortoString {
    my ($this, $string, $feature) = @_;

    my $ret_string;

    my $color;
    my $detail;

    for my $f (keys %{$this->{feature_color}}) {
	if ($this->{opt}{normal} && $feature =~ /<($f.*?)>/ ||
	    $this->{opt}{soft} && $feature =~ /<([^>]*$f.*?)>/ ||
	    $this->{opt}{hard} && $feature =~ /<($f)[:>]/) {
	    $color = $this->{feature_color}{$f};
	    if ($this->{opt}{detail}) {
		$detail ? $detail .= ",$1" : $detail = $1;
	    }
	    last;
	}
    }

    if ($this->{opt}{html}) {
	$ret_string .= "<font color = $color>" if ($color && !$detail);
	$ret_string .= $string;
	$ret_string .= "<font color = $color>" if ($color && $detail);
	$ret_string .= '<code class="attn">&lt;</code>' . $detail 
	    . '<code class="attn">&gt;</code>'if ($this->{opt}{detail} && $detail);
	$ret_string .= '</font>' if ($color);
    }
    else {
	$ret_string .= color($color) if ($color && !$detail);
	$ret_string .= $string;
	$ret_string .= color($color) if ($color && $detail);
	$ret_string .= "<$detail>" if ($this->{opt}{detail} && $detail);
	$ret_string .= color("reset") if ($color);
    }	

    $ret_string .= '|' if $this->{opt}{line};

    return $ret_string;
}

1;
