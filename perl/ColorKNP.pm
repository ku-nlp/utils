package ColorKNP;

# $Id$

# KNPの解析結果に色をつけるモジュール

use utf8;
use Term::ANSIColor;
use strict;

sub new {
    my ($this, $feature_color, $opt) = @_;

    $this = {
	opt => $opt
	};

    push @{$this->{feature_color}}, @{$feature_color};

    # オプションの初期値
    $this->{opt}{ansi} = 1 unless $this->{opt}{html};
    $this->{opt}{mrph} = 1 unless $this->{opt}{tag} || $this->{opt}{bnst};
    $this->{opt}{normal} = 1 unless $this->{opt}{hard} || $this->{opt}{soft};

    if ($this->{opt}{categorydefaultcolor}) {
	my @default_color;
	if ($this->{opt}{ansi}) {
	    @default_color = ( { feature => 'カテゴリ:組織・団体', color => 'blue' }, # ORGANIZATION
			       { feature => 'カテゴリ:人工物', color => 'magenta' }, # ARTIFACT
			       { feature => 'カテゴリ:人', color => 'red' }, # PERSON
			       { feature => 'カテゴリ:場所', color => 'green' }, # LOCATION
			       );
	} 
	else {
	    @default_color = ( { feature => 'カテゴリ:組織・団体', color => 'blue' },
			       { feature => 'カテゴリ:人工物', color => 'fuchsia' },
			       { feature => 'カテゴリ:人', color => 'red' },
			       { feature => 'カテゴリ:場所', color => 'green' },
			       { feature => 'カテゴリ:時間', color => 'aqua' },
			       );
	}
	unshift @{$this->{feature_color}}, @default_color;
    }

    if ($this->{opt}{nedefaultcolor}) {
	my @default_color;
	if ($this->{opt}{ansi}) {
	    @default_color = ( { feature => 'NE:ORGANIZATION', color => 'blue' },
			       { feature => 'NE:PERSON', color => 'red' },
			       { feature => 'NE:LOCATION', color => 'green' },
			       { feature => 'NE:ARTIFACT', color => 'magenta' },
			       { feature => 'NE:DATE', color => 'yellow' },
			       { feature => 'NE:TIME', color => 'cyan' },
			       { feature => 'NE:MONEY', color => 'olive' },
			       { feature => 'NE:PERCENT', color => 'maroon' } );
	} 
	else {
	    @default_color = ( { feature => 'NE:ORGANIZATION', color => 'blue' },
			       { feature => 'NE:PERSON', color => 'red' },
			       { feature => 'NE:LOCATION', color => 'green' },
			       { feature => 'NE:ARTIFACT', color => 'fuchsia' },
			       { feature => 'NE:DATE', color => 'plum' },
			       { feature => 'NE:TIME', color => 'aqua' },
			       { feature => 'NE:MONEY', color => 'olive' },
			       { feature => 'NE:PERCENT', color => 'maroon' } );
	}
	unshift @{$this->{feature_color}}, @default_color;
    }

    push @{$this->{decoration}}, { feature => 'NE', tag => 'u' };

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

    for (@{$this->{feature_color}}) {
	my $f = $_->{feature};
	my $c = $_->{color};

	if ($this->{opt}{normal} && $feature =~ /<($f.*?)>/ ||
	    $this->{opt}{soft} && $feature =~ /<([^>]*$f.*?)>/ ||
	    $this->{opt}{hard} && $feature =~ /<($f)[:>]/) {

	    $color = $c;
	    if ($this->{opt}{detail}) {
		$detail ? $detail .= ",$1" : $detail = $1;
	    }
	    last;
	}
    }

    my $tag;
    for (@{$this->{decoration}}) {
	my $f = $_->{feature};
	my $t = $_->{tag};

	if ($this->{opt}{normal} && $feature =~ /<($f.*?)>/ ||
	    $this->{opt}{soft} && $feature =~ /<([^>]*$f.*?)>/ ||
	    $this->{opt}{hard} && $feature =~ /<($f)[:>]/) {
	    $tag = $t;
	}
    }

    if ($this->{opt}{html}) {
	$ret_string .= "<$tag>" if $tag;
	$ret_string .= '<b>' if $this->{opt}{bold} && $color;
	$ret_string .= "<font color = $color>" if ($color && !$detail);
	$ret_string .= $string;
	$ret_string .= "<font color = $color>" if ($color && $detail);
	$ret_string .= '<code class="attn">&lt;</code>' . $detail 
	    . '<code class="attn">&gt;</code>'if ($this->{opt}{detail} && $detail);
	$ret_string .= '</font>' if ($color);
	$ret_string .= '</b>' if $this->{opt}{bold} && $color;
	$ret_string .= "</$tag>" if $tag;
    }
    else {
	$ret_string .= $this->{opt}{bold} ? color("bold $color") : color($color) if ($color && !$detail);
	$ret_string .= $string;
	$ret_string .= $this->{opt}{bold} ? color("bold $color") : color($color) if ($color && $detail);
	$ret_string .= "<$detail>" if ($this->{opt}{detail} && $detail);
	$ret_string .= color("reset") if ($color);
    }	

    $ret_string .= '|' if $this->{opt}{line};

    return $ret_string;
}

1;
