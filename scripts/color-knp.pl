#!/usr/bin/env perl

# $Id$

# usage: echo 'XXX' | juman | knp -tab | perl -I../perl color-knp.pl

use utf8;
binmode STDIN, ':encoding(euc-jp)';
binmode STDOUT, ':encoding(euc-jp)';
use strict;
use Getopt::Long;
use Encode;
use KNP;
use ColorKNP;

my ($sid, $flag, @feature_color, %opt);

GetOptions(\%opt, 'color=s', 'bold', 'html', 'ansi', 'soft', 'normal', 'hard', 'mrph', 'tag', 'bnst', 'detail', 'line', 'nedefaultcolor', 'h', 'help');

if ($opt{h} || $opt{help}) {
    die "Usage : $0\n" .
	"\t -color feature=color,feature=color...\n" .
	"\t\t color={red, green, yellow, blue, magenta, cyan} for ansi\n" .
	"\t\t color={red, maroon, yellow, olive, lime, green, aqua,\n" .
	"\t\t\tblue, navy, fuchsia, purple, silver, gray} for html\n" .
	"\t -[ansi(defalt)|html]\n" .
	"\t -[normal(defalt)|soft|hard]\n" .
	"\t -[mrph(defalt)|tag|bnst]\n" .
	"\t -detail\n" .
	"\t -line\n" .
	"\t -help\n";
}

$opt{ansi} = 1 if (!$opt{html});
$opt{mrph} = 1 if (!$opt{tag} && !$opt{bnst});
$opt{normal} = 1 if (!$opt{hard} && !$opt{soft});

# defaultの設定
# %feature_color = ("漢字" => "red");

if ($opt{color}) {
    for (split(',', decode('euc-jp', $opt{color}))) {
	if (/(.*)=(.*)/) {
	    push @feature_color, { feature => $1, color => $2 };
	}
    }
}

my $colorknp = new ColorKNP(\@feature_color, \%opt);

print "<html><body>\n" if ($opt{html}); 

my ($knp_buf);

while (<STDIN>) {

    $knp_buf .= $_;

    if (/\# S-ID:/) {
	/\# S-ID:\S+?(\d+)-\d+\s/;
	if ($sid && $sid ne $1) {
	    print "-" x 78 . "\n";
	    print "<BR>" if ($opt{html});
	}
	if ($sid ne $1) {
	    $sid = $1;
	    /\# (S-ID:.*)-\d/;
	    print "[$1]\n" if ($opt{ansi});
	    print "<font size=-1><font color = navy>[$1]</font></font><BR>\n" if ($opt{html});
	}
	else {
	    $sid = $1;
	}
    }
    elsif (/EOS/) {
	my $result = new KNP::Result($knp_buf);

	print $colorknp->AddColor($result);
	$knp_buf = "";

	print "<BR>" if ($opt{html});
	print "\n"; 

    }
}

print "</body></html><BR>\n" if ($opt{html});

