package CDB_Reader;

# $Id$

###############################################################################################
# CDB_Writerが分割して作成したcdbファイルを、1つのcdbファイルと等価に扱えるようにするモジュール
###############################################################################################

use strict;
use utf8;
use CDB_File;
use File::Basename;

sub new {
    my ($class, $keymapfile, $opt) = @_;
    my $this = {
	opt => $opt
    };

    my $dbdir = dirname($keymapfile);

    $this->{map} = [];

    my ($file0) = ($keymapfile =~ /([^\/]+)\.keymap/);
    $file0 .= '.0';
    tie my %cdb, 'CDB_File', "$dbdir/$file0" or die "$0: can't tie to $dbdir/$file0 $!\n";
    push(@{$this->{map}}, {key => undef, cdb => \%cdb});

    open(READER, '<:utf8', $keymapfile) or die "$!";
    while (<READER>) {
	chop($_);
	my ($k, $file) = split(' ', $_);
	tie my %cdb, 'CDB_File', "$dbdir/$file" or die "$0: can't tie to $dbdir/$file $!\n";
	push(@{$this->{map}}, {key => $k, cdb => \%cdb});
    }
    close(READER);

    bless $this;
}

sub DESTROY {
    my ($this) = @_;

    for (my $i = 1; $i < scalar(@{$this->{map}}); $i++) {
	untie $this->{map}[$i]{cdb};
    }
}

sub get {
    my ($this, $searchKey) = @_;

    my $cdb = $this->{map}[0]{cdb};
    for (my $i = 1; $i < scalar(@{$this->{map}}); $i++) {
	my $e = $this->{map}[$i];
	my $k = $e->{key};

	# keyが数字でsortされているオプション
	if ($this->{opt}{numerical_key}) {
	    last if ($searchKey < $k);
	}
	else {
	    last if ($searchKey lt $k);
	}

	$cdb = $e->{cdb};
    }

    return $cdb->{$searchKey};
}

sub getCDBs {
    my ($this) = @_;

    my @cdbs = ();
    foreach my $cdb (@{$this->{map}}) {
	push (@cdbs, $cdb->{cdb});
    }

    return \@cdbs;
}

1;
