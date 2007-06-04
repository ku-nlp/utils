#!/usr/bin/perl

# $Id$

use strict;
use Getopt::Long;
use Term::ANSIColor;
use KNP;

my ($sid, $flag, %feature, %opt);

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

# defaultの設定
# %feature = ("漢字" => "red");
# if ($opt{ansi}) {
#     %feature = ("NE:ORGANIZATION" => "blue",
# 		"NE:PERSON"        => "red",
# 		"NE:LOCATION"      => "green",
# 		"NE:ARTIFACT"      => "magenta",
# 		"NE:DATE"          => "yellow",
# 		"NE:TIME"          => "cyan",
# 		"NE:MONEY"         => "olive",
# 		"NE:PERCENT"       => "maroon");
# } 
# else {
#     %feature = ("NE:ORGANIZATION" => "blue",
# 		"NE:PERSON"        => "red",
# 		"NE:LOCATION"      => "green",
# 		"NE:ARTIFACT"      => "fuchsia",
# 		"NE:DATE"          => "lime",
# 		"NE:TIME"          => "aqua",
# 		"NE:MONEY"         => "olive",
# 		"NE:PERCENT"       => "maroon");
# }

if ($opt{color}) {
    for (split(',', $opt{color})) {
	if (/(.*)=(.*)/) {
	    $feature{$1} = $2;
	}
    }
}

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

	&output_result($result);
	$knp_buf = "";

	print "<BR>" if ($opt{html});
	print "\n"; 

    }
}

print "</body></html><BR>\n" if ($opt{html});

# 出力
sub output_result {
    my ($result) = @_;

    my $string;
    if ($opt{mrph}) {
	foreach my $mrph ($result->mrph) {
	    my $string = $mrph->midasi;

	    # 形態素の場合は品詞も対象に
	    my $feature =  "<" . $mrph->hinsi . ">" . "<" . $mrph->bunrui . ">" . $mrph->fstring;
	    &add_color($string, $feature);
	}
    }
    elsif ($opt{tag}) {
	foreach my $tag ($result->tag) {
	    my $string;
	    foreach my $mrph ($tag->mrph) {
		$string .= $mrph->midasi;
	    }
	    &add_color($string, $tag->fstring);
	}
    }
    elsif ($opt{bnst}) {
	foreach my $bnst ($result->bnst) {
	    my $string;
	    foreach my $mrph ($bnst->mrph) {
		$string .= $mrph->midasi;
	    }
	    &add_color($string, $bnst->fstring);
	}
    }
}

# 色をつける
sub add_color {
    my ($string, $feature) = @_;

    my $color;
    my $detail;

    for my $f (keys %feature) {
	if ($opt{normal} && $feature =~ /<($f.*?)>/ ||
	    $opt{soft} && $feature =~ /<([^>]*$f.*?)>/ ||
	    $opt{hard} && $feature =~ /<($f)[:>]/) {
	    $color = $feature{$f};
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
	print '</font>' if ($color);
    }
    else {
	print color($color) if ($color && !$detail);
	print $string;
	print color($color) if ($color && $detail);
	print "<$detail>" if ($opt{detail} && $detail);
	print color("reset") if ($color);
    }	

    print '|' if $opt{line};
}
