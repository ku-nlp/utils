#!/usr/bin/perl

use strict;
use Getopt::Long;
use Term::ANSIColor;

my ($sid, $flag, $color, $string, $feature, $detail, %color, %opt);

# defaultの設定
# %color = ("漢字" => "red");
# %color = ("NE:ORAGANIZATION" => "blue",
# 	  "NE:PERSON"        => "red",
# 	  "NE:LOCATION"      => "green",
# 	  "NE:ARTIFACT"      => "fuchsia",
# 	  "NE:DATE"          => "lime",
# 	  "NE:TIME"          => "aqua",
# 	  "NE:MONEY"         => "olive",
# 	  "NE:PERCENT"       => "maroon");

GetOptions(\%opt, 'color=s', 'html', 'ansi', 'soft', 'normal', 'hard', 'mrph', 'tag', 'bnst', 'detail', 'line', 'h', 'help');

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

if ($opt{color}) {
    %color=();
    for (split(',', $opt{color})) {
	/(.*)=(.*)/;
	$color{$1} = $2;
    }
}

print "<html><body>\n" if ($opt{html}); 

$_ = <STDIN>;
while ($_) {

    if (/\# S-ID:/) {
	$flag = 1;
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

    if (/EOS/) {
	if ($flag) {
	    print "\n"; 
	    print "<BR>" if ($opt{html});
	}
	$flag = 0;
    }

    if (!$flag || /\#/) {
	$_ = <STDIN>;
	next;
    }

    if ($opt{mrph}) {
	if (/^[\*\+]/) {
	    $_ = <STDIN>;
	    next;
	}
	$string = (split)[0];
	# 形態素の場合は品詞も対象に
	$feature =  "<" . (split)[3] . ">" . "<" . (split)[5] . ">" . (split)[-1];
	$_ = <STDIN>;
    }
    elsif ($opt{tag}) {
	if (/^[^\+]/) {
	    $_ = <STDIN>;
	    next;
	}
	$string = "";
	$feature = (split)[-1];
	$_ = <STDIN>;
	while ($_) {
	    last if (/^[\*\+]/ || /EOS/);
	    $string .= (split)[0];
	    $_ = <STDIN>;
	}
    }
    elsif ($opt{bnst}) {
	if (/^[^\*]/) {
	    $_ = <STDIN>;
	    next;
	}
	$string = "";
	$feature = (split)[-1];
	$_ = <STDIN>;
	while ($_) {
	    last if (/^[\*]/ || /EOS/);
	    $string .= (split)[0] if (!/^\+/);
	    $_ = <STDIN>;
	}
    }

    $color = $detail = "";
    for (keys(%color)) {
	if ($opt{normal} && $feature =~ /<($_.*?)>/ ||
	    $opt{soft} && $feature =~ /<([^>]*$_.*?)>/ ||
	    $opt{hard} && $feature =~ /<($_)[:>]/) {
	    $color = $color{$_};
	    if ($opt{detail}) {
		$detail ? $detail .= ",$1" : $detail = $1;
	    }
	    last;
	}
    }

    if ($opt{html}) {
	print "<font color = $color>" if ($color && !$detail);
	print $string;
	print "<font color = $color>" if ($color && $detail);
	print '<code class="attn">&lt;</code>' . $detail 
	    . '<code class="attn">&gt;</code>'if ($opt{detail} && $detail);
	print "</font>" if ($color);
    }
    else {
	print color($color) if ($color && !$detail);
	print $string;
	print color($color) if ($color && $detail);
	print "<$detail>" if ($opt{detail} && $detail);
	print color("reset") if ($color);
    }	

    if ($opt{line} && !/EOS/) {
	print "|";
    }

}
print "</body></html><BR>\n" if ($opt{html});
