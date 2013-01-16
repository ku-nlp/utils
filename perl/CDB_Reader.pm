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
    my $db_ref = tie my %cdb, 'CDB_File', "$dbdir/$file0" or die "$0: can't tie to $dbdir/$file0 $!\n";
    push(@{$this->{map}}, {key => undef, cdb => \%cdb});
    $this->{map}[-1]{db_ref} = $db_ref if $opt->{repeated_keys}; # keyが同じで値が異なるものが複数あるオプション

    open(READER, '<:utf8', $keymapfile) or die "$!";
    while (<READER>) {
	chomp($_);
	/^(.+) ([^ ]+)$/ or die "malformed keymap";
	my ($k, $file) = ($1, $2);
	my $db_ref = tie my %cdb, 'CDB_File', "$dbdir/$file" or die "$0: can't tie to $dbdir/$file $!\n";
	push(@{$this->{map}}, {key => $k, cdb => \%cdb});
	$this->{map}[-1]{db_ref} = $db_ref if $opt->{repeated_keys};
    }
    close(READER);

    bless $this;
}

sub DESTROY {
    my ($this) = @_;

    for (my $i = 0; $i < scalar(@{$this->{map}}); $i++) {
	untie $this->{map}[$i]{cdb};
    }
}

sub close {
    my ($this) = @_;

    for (my $i = 0; $i < scalar(@{$this->{map}}); $i++) {
	untie $this->{map}[$i]{cdb};
    }
}

sub get {
    my ($this, $searchKey, $opt) = @_;

    if ($opt->{exhaustive}) {
	for (my $i = 0; $i < scalar(@{$this->{map}}); $i++) {
	    my $value = $this->{map}[$i]{cdb}{$searchKey};
	    return $value if (defined $value);
	}
	return undef;
    } else {
	my $cdb = $this->{map}[0]{cdb};
	my $db_ref;
	$db_ref = $this->{map}[0]{db_ref} if $this->{opt}{repeated_keys};
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
	    $db_ref = $e->{db_ref} if $this->{opt}{repeated_keys};
	}
	if ($this->{opt}{repeated_keys}) {
	    return $db_ref->multi_get($searchKey);
	}
	else {
	    return $cdb->{$searchKey};
	}
    }
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
