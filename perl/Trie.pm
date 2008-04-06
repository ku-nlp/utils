package Trie;

# $Id$

use utf8;
use strict;
use Regexp::Trie;

sub new {
    my ($this) = @_;

    $this = {
	trie => Regexp::Trie->new
    };

    bless $this;

    return $this;
}

sub DESTROY {
    my ($this) = @_;
}

# stringをtrie構造に追加
sub Add {
    my ($this, $string) = @_;

    $this->{trie}->add($string);
}

# 正規表現をはく
sub Regexp {
    my ($this) = @_;

    return $this->{trie}->regexp;
}

1;

