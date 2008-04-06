package Trie;

# $Id$

use utf8;
use strict;
use Regexp::Trie;
use Unicode::Japanese;
use JICFS;

sub new {
    my ($this, $opt) = @_;

    $this = {
	trie => Regexp::Trie->new,
	jicfs => new JICFS,
	opt => $opt
    };

    # 形態素解析を行う
    if ($opt->{usejuman}) {
	require Juman;
	$this->{juman} = new Juman;
    }

    bless $this;

    return $this;
}

sub DESTROY {
    my ($this) = @_;
}

# stringをtrie構造に追加
sub Add {
    my ($this, $string) = @_;

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    if ($this->{opt}{usejuman}) {
	$string = $this->{jicfs}->ArrangeSentence($string);
	my $ref  = $this->{trie};
	my $result = $this->{juman}->analysis($string);

	for my $mrph ($result->mrph){
	    my $repname = $this->GetRepname($mrph);

	    $ref->{$repname} ||= {};
	    $ref = $ref->{$repname};
	}
	$ref->{''} = 1; # { '' => 1 } as terminator
    }
    else {
	$this->{trie}->add($string);
    }
}

sub GetRepname {
    my ($this, $mrph) = @_;

    my $repname = $mrph->repname;

    if ($repname) {
	return $repname;
    }
    else {
	return $mrph->genkei . '/' . $mrph->yomi;
    }
}

# 正規表現をはく
sub Regexp {
    my ($this) = @_;

    return $this->{trie}->regexp;
}

1;

