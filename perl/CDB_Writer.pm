package CDB_Writer;

# $Id$

#########################################
# CDBファイルを分割して作成するモジュール
#########################################

use strict;
use CDB_File;
use Encode;
use File::stat;

sub new {
    my ($class, $dbname, $keyfp, $limit_file_size, $fetch) = @_;

    my $this = {
	dbname => $dbname,
	# デフォルトは3.5GB
	limit_file_size => 3.5 * (1024**3),
	# 100万レコードが保存されるたびにファイルサイズが
	# limit_file_sizeを超えていないかどうかを確認
	fetch => 1000000,
	record_counter => 0,
	num_of_cdbs => 0
    };

    $this->{limit_file_size} = $limit_file_size if (defined $limit_file_size);
    $this->{fetch} = $fetch if (defined $fetch);

    my $file = "$this->{dbname}.$this->{num_of_cdbs}";
    my $tmpfile = "$file.$$";
    $this->{cdb} = new CDB_File ($file, $tmpfile) or die;
    $this->{tmpfile} = $tmpfile;
    open($this->{keymap}, "> $keyfp") or die;

    bless $this;
}

sub close {
    my ($this) = @_;

    $this->{cdb}->finish();
    close($this->{keymap});
}

sub DESTROY {
    my($this) = @_;
}

sub add {
    my($this, $key, $value) = @_;

    if ($this->{record_counter} % $this->{fetch} == 0) {
	my $size = stat($this->{tmpfile})->size;
	if ($size > $this->{limit_file_size}) {
	    $this->{cdb}->finish();
	    $this->{num_of_cdbs}++;

	    my $file = "$this->{dbname}.$this->{num_of_cdbs}";
	    my $tmpfile = $file . ".$$";
	    $this->{cdb} = new CDB_File ($file, $tmpfile) or die;
	    $this->{tmpfile} = $tmpfile;
	    $this->{record_counter} = 0;

	    # 最も小さいキーの値とCDBファイルの対応を保存
	    print {$this->{keymap}} "$key $file\n";
	}
    }

    $this->{record_counter}++;
    $this->{cdb}->insert($key, $value);
}

1;
