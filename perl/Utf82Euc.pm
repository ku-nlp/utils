package Utf82Euc;

# $Id$

use strict;
use Encode;

sub new {
    my ($this) = @_;

    $this = {};

    bless $this;
}

sub DESTROY {

}

sub Conv3bytecode_to_geta {
    my ($this, $buf) = @_;

    my $conv_buf = encode('euc-jp', $buf, sub {'во'});

    my ($ret_buf);

    while ($conv_buf =~ /([^\x80-\xfe]|[\x80-\x8e\x90-\xfe][\x80-\xfe]|\x8f[\x80-\xfe][\x80-\xfe])/g) {
	my $chr = $1;
	if ($chr =~ /^\x8f/) { # 3byte code (JISX0212)
	    $ret_buf .= 'во';
	}
	else {
	    $ret_buf .= $chr;
	}
    }

    return $ret_buf;
}

1;
