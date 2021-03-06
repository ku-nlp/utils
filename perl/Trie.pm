package Trie;

# $Id$

use utf8;
use strict;
use Encode;
use BerkeleyDB;
use Storable;
use MLDBM qw(BerkeleyDB::Hash Storable);
use CDB_File;

sub new {
    my ($this, $opt) = @_;

    $this = {
	opt => $opt
    };

    # 形態素解析を行う
    if ($opt->{usejuman}) {
	require Juman;
	$this->{juman} = new Juman;
    }
    $this->{trie} = {};

    bless $this;

    return $this;
}

sub DESTROY {
    my ($this) = @_;

    if ($this->{opt}{retrievedb}) {
	untie %{$this->{trie}};
    }
}

# テキスト中から文字列をみつける
sub DetectString {
    my ($this, $mrphs, $keys, $option) = @_;

    unless ($keys) {
	@{$keys} = $this->{opt}{userepname} ? map { $this->GetRepname($_) } @{$mrphs} : map { $_->midasi } @{$mrphs};
    }

    my $outputtext;

    my $mrph_num = scalar @{$mrphs};
    for (my $i = 0; $i < $mrph_num; $i++) {
	my $match_flag = 0;
	my $match_id;
	my $end_j;
	my $ref = $this->{trie};

	my $j = $i;
	while ($j <= $mrph_num) {

	    # terminator
	    if ($ref->{''}) {
		$match_flag = 1;
		$match_id = $ref->{''};
		$end_j = $j - 1;

		# $retに登録されているエントリ数のカウント
		# 1 ... エントリ数 1
		# 2 ... エントリ数 2 以上
		my $_cnt = 0;
		while (my ($_k, $_v) = each %$ref) {
		    last if ($_cnt > 1);
		    $_cnt++;
		}

		# 唯一のterminator
		if ($_cnt == 1) {
		    last;
		}
	    }

	    # 先頭はskipしない
	    if ($this->{opt}{skip} && $i != $j && $this->SkipMrph($keys->[$j], $mrphs->[$j])) {
		$j++;
		next;
	    }

	    if (defined $ref->{$keys->[$j]}) {
		$ref = $ref->{$keys->[$j]};
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

	    if (defined $option->{embed_tag}) {
		$outputtext .= qq(<span id="$match_id">);
	    }
	    elsif (defined $option->{output_juman}) {
		my $add_imis = "$match_id:$i-$end_j";

		# 情報を付与する位置
		my $add_imis_pos = $option->{add_end_pos} ? $end_j : $i;
		$mrphs->[$add_imis_pos]->push_imis($add_imis);
		for my $doukei ($mrphs->[$add_imis_pos]->doukei) {
		    $doukei->push_imis($add_imis);
		}
		for my $k ( $i .. $end_j) {
		    $outputtext .= $mrphs->[$k]->spec;
		    for my $doukei ($mrphs->[$k]->doukei) {
			$outputtext .= '@ ' . $doukei->spec;
		    }
		}
	    }
	    else {
		$outputtext .= '「';
	    }
	    unless (defined $option->{output_juman}) {
		$outputtext .= $string;
		$outputtext .= defined $option->{embed_tag} ? '</span>' : '」';
	    }

	    # 最後にマッチしたところまで進める
	    $i = $end_j;

	    if ($option->{detected_strings}) {
		push @{$option->{detected_strings}}, $string;
	    }
	}
	# マッチしなかった
	else {
	    if (defined $option->{output_juman}) {
		$outputtext .= $mrphs->[$i]->spec;
		for my $doukei ($mrphs->[$i]->doukei) {
		    $outputtext .= '@ ' . $doukei->spec;
		}

	    }
	    else {
		$outputtext .= $mrphs->[$i]->midasi;
	    }
	}
    }

    $outputtext .= "EOS\n" if defined $option->{output_juman};
 
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

    my $ref  = $this->{trie};
    if ($this->{opt}{usejuman}) {
	my @mrphs = $this->{juman}->analysis($string)->mrph;
	$this->AddMorphList(\@mrphs, $id);
    }
    else {
	$this->AddString($string);
    }
}

# 形態素列を trie 構造に追加
sub AddMorphList {
    my ($this, $mrphs, $id) = @_;

    my $ref  = $this->{trie};
    for my $mrph (@$mrphs) {
	my $string = $this->{opt}{userepname} ? $this->GetRepname($mrph) : $mrph->midasi;

	next if $this->{opt}{skip} && $this->SkipMrph($string);

	$ref->{$string} ||= {};
	$ref = $ref->{$string};
    }
    $ref->{''} = defined $id ? $id : 1; # { '' => 1 } as terminator
}

sub AddString {
    my ($this, $string, $id) = @_;

    my $ref  = $this->{trie};
    for my $char (split //, $string) {
	$ref->{$char} ||= {};
	$ref = $ref->{$char};
    }
    $ref->{''} = defined $id ? $id : 1; # { '' => 1 } as terminator
}

# Trie構築時、解析時ともにスキップする形態素をチェック
sub SkipMrph {
    my ($this, $string, $mrph) = @_;

    if (defined $mrph) {
	return 1 if $mrph->genkei eq 'する';
	return 1 if $mrph->bunrui eq '記号';
    }
    return 1 if $string eq '　' || $string eq '　/　';
}

sub MakeDB {
    my ($this, $dbname) = @_;

    my %hash;
    my $db = tie %hash, 'MLDBM', -Filename => $dbname, -Flags => DB_CREATE | DB_TRUNCATE or die "Cannot tie '$dbname'";

    $this->DBFilter($db);

    while (my ($key, $value) = each %{$this->{trie}}) {
        $hash{$key} = $value;
    }

    untie %hash;
}

sub RetrieveDB {
    my ($this, $dbname) = @_;

    $this->{opt}{retrievedb} = 1;

    die "Can't find db ($dbname)\n" unless -e $dbname;
    my $db = tie %{$this->{trie}}, 'MLDBM', -Filename => $dbname, -Flags => DB_RDONLY or die "Cannot tie '$dbname'";

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

1;

