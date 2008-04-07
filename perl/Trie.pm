package Trie;

# $Id$

use utf8;
use strict;
use Encode;
use Regexp::Trie;
use Unicode::Japanese;
use JICFS;
use BerkeleyDB;
use Storable;
use MLDBM qw(BerkeleyDB::Hash Storable);

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

    if ($this->{opt}{retrievedb}) {
	untie %{$this->{trie}};
    }
}

# テキスト中から商品名をみつける
sub DetectGoods {
    my ($this, $mrphs, $repnames) = @_;

    unless ($repnames) {
	@{$repnames} = map { $this->GetRepname($_) } @{$mrphs};
    }

    my $outputtext;

    for (my $i = 0; $i < @{$mrphs}; $i++) {
	my $match_flag = 0;
	my $end_j;
	my $ref = $this->{trie};

	my $j = $i;
	while ($j <= @{$mrphs}) {
	    # terminator
	    if ($ref->{''}) {
		$match_flag = 1;
		$end_j = $j - 1;
		
		# 唯一のterminator
		if (scalar keys %$ref == 1) {
		    last;
		}
	    }

	    if (defined $ref->{$repnames->[$j]}) {
		$ref = $ref->{$repnames->[$j]};
		$j++;
	    }
	    else {
		last;
	    }
	}
	# マッチした
	if ($match_flag) {
	    $outputtext .= '「';
	    for my $k ( $i .. $end_j) {
		$outputtext .= $mrphs->[$k]->midasi;
	    }
	    $outputtext .= '」';

	    # 最後にマッチしたところまで進める
	    $i = $end_j;
	}
	# マッチしなかった
	else {
	    $outputtext .= $mrphs->[$i]->midasi;
	}
    }
    return $outputtext;
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

sub MakeDB {
    my ($this, $dbname) = @_;

    my %hash;
    my $db = tie %hash, 'MLDBM', -Filename => $dbname, -Flags => DB_CREATE or die "Cannot tie '$dbname'";

    $this->DBFilter($db);

    while (my ($key, $value) = each %{$this->{trie}}) {
        $hash{$key} = $value;
    }

    untie %hash;
}

sub RetrieveDB {
    my ($this, $dbname) = @_;

    $this->{opt}{retrievedb} = 1;
    my $db = tie %{$this->{trie}}, 'MLDBM', -Filename => $dbname or die "Cannot tie '$dbname'";

    $this->DBFilter($db);
}

sub DBFilter {
    my ($this, $db) = @_;

    # filter setting
    $db->filter_fetch_key(sub{$_ = &decode('utf-8', $_)});
    $db->filter_store_key(sub{$_ = &encode('utf-8', $_)});
    $db->filter_fetch_value(sub{$_ = &decode('utf-8', $_)});
    $db->filter_store_value(sub{$_ = &encode('utf-8', $_)});

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

