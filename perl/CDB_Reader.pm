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
    my ($class, $keymapfile) = @_;
    my $this;

    my $dbdir = dirname($keymapfile);

    $this->{map} = [];
    open(READER, $keymapfile);
    while (<READER>) {
	chop($_);
	my ($k, $file) = split(' ', $_);
	if (scalar(@{$this->{map}}) < 1) {
	    my ($file0) = ($file =~ /(.+?)\.\d+/);
	    $file0 .= ".0";
	    tie my %cdb, 'CDB_File', "$dbdir/$file0" or die "$0: can't tie to $dbdir/$file0 $!\n";
	    push(@{$this->{map}}, {key => undef, cdb => \%cdb});
	}

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
	last if ($searchKey lt $k);

	$cdb = $e->{cdb};
    }

    return $cdb->{$searchKey};
}

1;
