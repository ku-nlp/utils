package Trie;

# $Id$

use utf8;
use strict;
use Encode;
use URI::Escape qw/uri_escape_utf8/;
use Regexp::Trie;
use Unicode::Japanese;
use JICFS;
use BerkeleyDB;
use Storable;
use MLDBM qw(BerkeleyDB::Hash Storable);
use CDB_File;

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

    tie(%{$this->{JanListDB}}, 'CDB_File', $Constant::JanListDB) or die "$!\n";

    bless $this;

    return $this;
}

sub DESTROY {
    my ($this) = @_;

    if ($this->{opt}{retrievedb}) {
	untie %{$this->{trie}};
    }

    untie %{$this->{JanListDB}};
}

# テキスト中から商品名をみつける
sub DetectGoods {
    my ($this, $mrphs, $repnames, $option) = @_;

    unless ($repnames) {
	@{$repnames} = map { $this->GetRepname($_) } @{$mrphs};
    }

    my $outputtext;

    for (my $i = 0; $i < @{$mrphs}; $i++) {
	my $match_flag = 0;
	my $match_id;
	my $end_j;
	my $ref = $this->{trie};

	my $j = $i;
	while ($j <= @{$mrphs}) {

	    if ($this->SkipMrph($repnames->[$j])) {
		$j++;
		next;
	    }

	    # terminator
	    if ($ref->{''}) {
		$match_flag = 1;
		$match_id = $ref->{''};
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
	    my $string;
	    for my $k ( $i .. $end_j) {
		$string .= $mrphs->[$k]->midasi;
	    }

	    if (defined $option->{html}) {
		my $token = $this->{opt}{token};

		my $jan_name = decode('utf8', $this->{JanListDB}{$match_id});

		# $product_name_for_slip_kanjiが正式名称
		my ($product_name_kanji, $product_name_for_slip_kanji) = split(':', $jan_name);

		$outputtext .=  qq(<a target="_blank" onMouseOver="return overlib('$match_id/$product_name_kanji/$product_name_for_slip_kanji')" onMouseOut="return nd()" href="http://api.rakuten.co.jp/rws/2.0/rest?developerId=$token&operation=ItemSearch&version=2009-04-15&keyword=);
		$outputtext .= uri_escape_utf8($product_name_kanji);
		$outputtext .= qq(">);
	    }
	    else {
		$outputtext .= '「';
	    }
	    $outputtext .= $string;
	    $outputtext .= defined $option->{html} ? '</a>' : '」';

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
    my ($this, $string, $id) = @_;

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    return unless $string;

    # 数字だけ
    return if $string =~ /^\d+$/;

    if ($this->{opt}{usejuman}) {
	$string = $this->{jicfs}->ArrangeSentence($string);
	my $ref  = $this->{trie};
	my $result = $this->{juman}->analysis($string);

	for my $mrph ($result->mrph) {
	    my $repname = $this->GetRepname($mrph);

	    next if $this->SkipMrph($repname);

	    $ref->{$repname} ||= {};
	    $ref = $ref->{$repname};
	}
	$ref->{''} = defined $id ? $id : 1; # { '' => 1 } as terminator
    }
    else {
	$this->{trie}->add($string);
    }
}

# Trie構築時、解析時ともにスキップする形態素をチェック
sub SkipMrph {
    my ($this, $repname) = @_;

    return 1 if $repname eq '　/　';
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

