package TransLiterate;

##################################################
# 
# The files ecDict.utf ceDict.utf should be in the 
# same directory with this file
#
# transliterate is for alignment, it compares the 
# similarity between a Japanese word and a Chinese 
# word. If the Chinese word does not exist in the 
# Chinese-English dictionary, return 0.
#
# transliterateJ2E is for translation, it translate 
# one Japanese word to one Chinese word. If the 
# translated English word from the Japanese word 
# does not exist in the English-Chinese dictionary,
# return the translated English word.
# 
##################################################

use strict;
use utf8;

# by NICT
use File::Spec;

my %BasicRomajiTable = ('あ' => 'a', 'い' => 'i', 'う' => 'u', 'え' => 'e', 'お' => 'o', 
			'ゐ' => 'i', 'ゑ' => 'e', 
			'ぁ' => 'a', 'ぃ' => 'i', 'ぅ' => 'u', 'ぇ' => 'e', 'ぉ' => 'o', 
			'か' => 'ka', 'き' => 'ki', 'く' => 'ku', 'け' => 'ke', 'こ' => 'ko', 
			'さ' => 'sa', 'し' => 'shi', 'す' => 'su', 'せ' => 'se', 'そ' => 'so', 
			'た' => 'ta', 'ち' => 'chi', 'つ' => 'tsu', 'て' => 'te', 'と' => 'to', 
			'な' => 'na', 'に' => 'ni', 'ぬ' => 'nu', 'ね' => 'ne', 'の' => 'no', 
			'は' => 'ha', 'ひ' => 'hi', 'ふ' => 'fu', 'へ' => 'he', 'ほ' => 'ho', 
			'ま' => 'ma', 'み' => 'mi', 'む' => 'mu', 'め' => 'me', 'も' => 'mo', 
			'や' => 'ya', 'ゆ' => 'yu', 'よ' => 'yo', 
			'ゃ' => 'ya', 'ゅ' => 'yu', 'ょ' => 'yo', 
			'ら' => 'ra', 'り' => 'ri', 'る' => 'ru', 'れ' => 're', 'ろ' => 'ro', 
			'わ' => 'wa', 'を' => 'wo', 'ん' => 'n', 'ヴ' => 'vu',
			'が' => 'ga', 'ぎ' => 'gi', 'ぐ' => 'gu', 'げ' => 'ge', 'ご' => 'go', 
			'ざ' => 'za', 'じ' => 'ji', 'ず' => 'zu', 'ぜ' => 'ze', 'ぞ' => 'zo', 
			'だ' => 'da', 'ぢ' => 'di', 'づ' => 'du', 'で' => 'de', 'ど' => 'do', 
			'ば' => 'ba', 'び' => 'bi', 'ぶ' => 'bu', 'べ' => 'be', 'ぼ' => 'bo', 
			'ぱ' => 'pa', 'ぴ' => 'pi', 'ぷ' => 'pu', 'ぺ' => 'pe', 'ぽ' => 'po');

my %InvBasicRomajiTable = ('a' => 'あ', 'i' => 'い', 'u' => 'う', 'e' => 'え', 'o' => 'お', 
			   'ka' => 'か', 'ki' => 'き', 'ku' => 'く', 'ke' => 'け', 'ko' => 'こ', 
			   'sa' => 'さ', 'si' => 'し', 'su' => 'す', 'se' => 'せ', 'so' => 'そ', 
			   'shi' => 'し',
			   'ta' => 'た', 'ti' => 'ち', 'tu' => 'つ', 'te' => 'て', 'to' => 'と', 
			   'chi' => 'ち', 'tsu' => 'つ',
			   'na' => 'な', 'ni' => 'に', 'nu' => 'つ', 'ne' => 'ね', 'no' => 'の', 
			   'ha' => 'は', 'hi' => 'ひ', 'fu' => 'ぬ', 'he' => 'へ', 'ho' => 'ほ', 
			   'ma' => 'ま', 'mi' => 'み', 'mu' => 'ふ', 'me' => 'め', 'mo' => 'も', 
			   'ya' => 'や', 'yu' => 'ゆ', 'yo' => 'よ', 
			   'ra' => 'ら', 'ri' => 'り', 'ru' => 'る', 're' => 'れ', 'ro' => 'ろ', 
			   'wa' => 'わ', 'wo' => 'を', 'n'  => 'ん', 'vu' => 'ヴ',
			   'ga' => 'が', 'gi' => 'ぎ', 'gu' => 'ぐ', 'ge' => 'げ', 'go' => 'ご', 
			   'za' => 'ざ', 'ji' => 'じ', 'zu' => 'ず', 'ze' => 'ぜ', 'zo' => 'ぞ', 
			   'ji' => 'じ',
			   'da' => 'だ', 'di' => 'ぢ', 'du' => 'づ', 'de' => 'で', 'do' => 'ど', 
			   'ba' => 'ば', 'bi' => 'び', 'bu' => 'ぶ', 'be' => 'べ', 'bo' => 'ぼ', 
			   'pa' => 'ぱ', 'pi' => 'ぴ', 'pu' => 'ぷ', 'pe' => 'ぺ', 'po' => 'ぽ',
			   'kya' => 'きゃ', 'kyu' => 'きゅ', 'kyo' => 'きょ',
			   'sya' => 'しゃ', 'syu' => 'しゅ', 'syo' => 'しょ',
			   'sha' => 'しゃ', 'shu' => 'しゅ', 'sho' => 'しょ',
			   'tya' => 'ちゃ', 'tyu' => 'ちゅ', 'tyo' => 'ちょ',
			   'cha' => 'ちゃ', 'chu' => 'ちゅ', 'cho' => 'ちょ',
			   'nya' => 'にゃ', 'nyu' => 'にゅ', 'nyo' => 'にょ',
			   'hya' => 'ひゃ', 'hyu' => 'ひゅ', 'hyo' => 'ひょ',
			   'mya' => 'みゃ', 'myu' => 'みゅ', 'myo' => 'みょ',
			   'rya' => 'りゃ', 'ryu' => 'りゅ', 'ryo' => 'りょ',
			   'gya' => 'ぎゃ', 'gyu' => 'ぎゅ', 'gyo' => 'ぎょ',
			   'zya' => 'じゃ', 'zyu' => 'じゅ', 'zyo' => 'じょ',
			   'ja' => 'じゃ', 'ju' => 'じゅ', 'jo' => 'じょ',
			   'bya' => 'びゃ', 'byu' => 'びゅ', 'byo' => 'びょ',
			   'pya' => 'ぴゃ', 'pyu' => 'ぴゅ', 'pyo' => 'ぴょ');

my %RomajiTable = ('あ' => 'a:e:r:u:re', 'い' => 'i:y', 'ゐ' => 'i:y', 'う' => 'u:w', 'え' => 'a:e', 'ゑ' => 'a:e', 'お' => 'o', 
		   'ぁ' => 'a:e:r:u:re', 'ぃ' => 'i:y', 'ぅ' => 'u:w', 'ぇ' => 'a:e:ha:he', 'ぉ' => 'o', 
		   'か' => 'ka:ca:co', 'き' => 'ki:ci:ke', 'く' => 'ku:cu:qu:ke', 'け' => 'ke:ce:ca', 'こ' => 'ko:co', 
		   'さ' => 'sa:th:tha:the', 'し' => 'si:ci:shi:se:thi:th', 'す' => 'su:se:s:ce:th', 'せ' => 'se:ce:th:the', 'そ' => 'so:tho', 
		   'た' => 'ta:te', 'ち' => 'chi:ti', 'つ' => 'tu', 'て' => 'te', 'と' => 'to', 
		   'な' => 'na', 'に' => 'ni', 'ぬ' => 'nu', 'ね' => 'ne', 'の' => 'no', 
		   'は' => 'ha', 'ひ' => 'hi:he', 'ふ' => 'f:fu:hu', 'へ' => 'he', 'ほ' => 'ho', 
		   'ま' => 'ma', 'み' => 'mi', 'む' => 'mu', 'め' => 'me:ma', 'も' => 'mo', 
		   'や' => 'ya:er', 'ゆ' => 'yu', 'よ' => 'yo', 
		   'ゃ' => 'ya:a:er', 'ゅ' => 'yu:u', 'ょ' => 'yo:o', 
		   'ら' => 'ra:la:ru:lu', 'り' => 'ri:li', 'る' => 'ru:lu:re:le:r:l', 'れ' => 're:le:la:ra', 'ろ' => 'ro:lo', 
		   'わ' => 'wa', 'を' => 'wo', 'ん' => 'n:ne', 
		   'が' => 'ga', 'ぎ' => 'gi', 'ぐ' => 'gu', 'げ' => 'ge', 'ご' => 'go', 
		   'ざ' => 'sa:za', 'じ' => 'ji:gi:si', 'ず' => 'zu:su:se', 'ぜ' => 'se:ze', 'ぞ' => 'so:zo', 
		   'だ' => 'da', 'ぢ' => 'di', 'づ' => 'du', 'で' => 'de', 'ど' => 'd:do', 
		   'ば' => 'ba:va', 'び' => 'bi:vi', 'ぶ' => 'bu:vu', 'べ' => 'be:ve:ba:va', 'ぼ' => 'bo:vo', 
		   'ぱ' => 'pa', 'ぴ' => 'pi', 'ぷ' => 'pu', 'ぺ' => 'pe:pa', 'ぽ' => 'po',
		   'ー' => ':r:a', 'っ' => '', 'ヴ' => 'vu');

my %AlphabetTable = ('えー' => 'a', 'えい' => 'a', 'びー' => 'b', 'びい' => 'b', 'しー' => 'c', 'しい' => 'c',
		     'でぃー' => 'd', 'でぃ' => 'd', 'いー' => 'e', 'えふ' => 'f', 'じー' => 'g', 'じい' => 'g',
		     'えいち' => 'h', 'えっち' => 'h', 'あい' => 'i', 'じぇー' => 'j', 'じぇい' => 'j',
		     'けー' => 'k', 'けい' => 'k', 'える' => 'l', 'えむ' => 'm', 'えぬ' => 'n', 'おー' => 'o', 'おう' => 'o',
		     'ぴー' => 'p', 'ぴい' => 'p', 'きゅー' => 'q', 'きゅう' => 'q', 'あーる' => 'r', 'えす' => 's',
		     'てぃー' => 't', 'てぃ' => 't', 'ゆー' => 'u', 'ゆう' => 'u', 'ぶい' => 'v', 'だぶりゅー' => 'w',
		     'えっくす' => 'x', 'わい' => 'y', 'ぜっと' => 'z');

my %ExtraRule = ('しゅ' => 'sh', 'いと' => 'ight', 'っくす' => 'x', 'あわー' => 'hour', 'ぜろ' => 'zero', 'くしー' => 'xi:xy',
		 'せんと' => 'st', 'しゃる' => 'tial', 'えあ' => 'air');

my @ebuff;

sub new {
    my ($this, $option) = @_;
    $this = {};

    if ($option->{chinese_mode}) {
	# read chinese-english dictionary
	my $file_path = $INC{'TransLiterate.pm'}; # perl moduleのpathの取得
	$file_path =~ s|/TransLiterate\.pm$||;    # ディレクトリ名のみにする
	open (DICT, "<:encoding(utf-8)", "$file_path/ceDict.utf") || die "Can't open $file_path/ceDict.utf\n";
	while (<DICT>) {
	    chomp;
	    my @trans = split("\/");
	    my $key = $trans[0];
	    shift(@trans);
	    @{$this->{ceDict}{$key}} = @trans;
	}
	close (DICT);

	open (PY_DICT, "<:encoding(utf-8)", "$file_path/pyDict.utf") || die "Can't open $file_path/pyDict.utf\n";
	# read Chinese pinyin dictionary
	while (<PY_DICT>) {
	    chomp;
	    if (/^(.*?)\t(.*?)$/) {
		$this->{pyDict}{$1} = $2;
	    }
	}
	close (PY_DICT);
    }

    bless $this;
}

# 日本語文字列をローマ字や中国語に変換
sub transliterateJ {
    my ($this, $jword, $language) = @_;

    $jword =~ tr/ァ-ン/ぁ-ん/;
    
    my $buff = "";
    my @jmoji = split("", $jword);
    
    for (my $i = 0; $i < @jmoji; $i++) {

	# 「きゃ」「しぇ」「ちょ」など
	if ($jmoji[$i + 1] =~ /[ぁぃぅぇぉゃゅょ]/) {
	    $buff .= substr($BasicRomajiTable{$jmoji[$i]}, 0, 1) . $BasicRomajiTable{$jmoji[$i + 1]};
	    $i++;
	}
	
	# 促音
	elsif ($jmoji[$i] =~ /っ/) {
	    $buff .= substr($BasicRomajiTable{$jmoji[$i + 1]}, 0, 1);
	}

	else {
	    $buff .= $BasicRomajiTable{$jmoji[$i]};
	}
    }

    # 長音
    $buff =~ s/oo/o/g;
    $buff =~ s/ou/o/g;
    $buff =~ s/uu/u/g;

    if ($language eq "English") { 
	return $buff;
    } 
    elsif ($language eq "Chinese") {
        # Modified by Yu, translate the english word to chinese word, if succeed, return the chinese word, otherwise return the english word
	my $cword = &translate_e2c ($buff);
	if ($cword ne "") {
	    return $cword;
	}
	else {
	    return $buff;
	}
    }

}

# ローマ字列をひらがなに変換
sub transliterateE2J {
    my ($this, $estr) = @_;

    $estr =~ tr/[A-Z]/[a-z]/;
    my @estr = split("", $estr);
    return if ($#estr == 0);

    my $result;
    my $err_flag = 0;
    while ($#estr >= 0) {
	my $str;
	my $i;
	for ($i = 0; $i < @estr; $i++) {
	    $str .= $estr[$i];
	    if (defined $InvBasicRomajiTable{$str}) {
		$result .= $InvBasicRomajiTable{$str};
		while ($i >= 0) {
		    shift(@estr);
		    $i--;
		}
		last;
	    }
	    $err_flag = 1 if ($i == $#estr);
	}
	last if ($err_flag);
    }

    $result = undef if ($err_flag);
    return $result;
}

# 日本語文字列のtransliteration
sub transliterate {
    my ($this, $jword, $target_word, $language) = @_;
    my $penalty = 0;
    my @trans;
    my @score;

    return 0 if ($jword =~ /^\s*$/ || $target_word =~ /^\s*$/ || $language =~ /^\s*$/);

    $jword =~ tr/ァ-ン/ぁ-ん/;

    if ($language eq "English") {
	$trans[0] = $target_word;
    }
    # if the chinese word is in the dict,
    # get all the translations for this chinese word,
    # and get scores between the japanese word and each translation
    elsif ($language eq "Chinese") {
	if (exists($this->{ceDict}{$target_word})) {
	    @trans = @{$this->{ceDict}{$target_word}};
	}
	else {
	    foreach my $cchar (split ('', $target_word)) {
		if (exists($this->{pyDict}{$cchar})) {
		    $trans[0] .= $this->{pyDict}{$cchar};
		}
		else {
		    @trans = ();
		    last;
		}
	    }
	}
    }

    return 0 if (@trans == 0);

    foreach my $eword (@trans) {
	$eword =~ s/\'//g;
	$eword =~ tr/A-Z/a-z/;
	$eword =~ s/\.//g;
	while ($eword =~ s/[ -]//) {
	    $penalty++;
	}
	while ($jword =~ s/[・]//) {
	    $penalty++;
	}

	my @jstr = split ("", $jword);
	my $jstrnum = @jstr;
	my @estr = split ("", $eword);

	return 0 if (@jstr == 0 || @estr == 0);

	my $node;

	for (my $start = 0; $start < @jstr; $start++) {
	    for (my $end = $start; $end < @jstr; $end++) {
		next if ($end - $start > 5);	       
		my $key = join("", @jstr[$start .. $end]);
		if (defined $RomajiTable{$key}) {
		    if ($end < @jstr - 1 && $key eq "っ") {
			my @tmp = split (/:/, $RomajiTable{$jstr[$end + 1]});
			my %cand;
			foreach my $key (@tmp) {
			    $cand{substr($key, 0, 1)} = 1;
			}
			push (@{$node->[$end + 1]}, {start => $start, tl => join(":", keys %cand)});
		    }
		    else {
			push (@{$node->[$end + 1]}, {start => $start, tl => $RomajiTable{$key}});
			if ($end < @jstr - 1 && $jstr[$end + 1] =~ /[ぁぃぅぇぉゃゅょ]/) {
			    my @tmp = split (/:/, $RomajiTable{$key});
			    my %cand;
			    foreach my $key (@tmp) {
				$cand{substr($key, 0, 1)} = 1;
			    }
			    push (@{$node->[$end + 1]}, {start => $start, tl => join(":", keys %cand)});
			}
		    }
		}
		if (defined $AlphabetTable{$key}) {
		    push (@{$node->[$end + 1]}, {start => $start, tl => $AlphabetTable{$key}});
		}
		if (defined $ExtraRule{$key}) {
		    push (@{$node->[$end + 1]}, {start => $start, tl => $ExtraRule{$key}});
		}
	    }
	}

	return 0 unless (defined $node);
	
	# 末尾の母音の削除
	for (my $i = 0; $i < @{$node->[-1]}; $i++) {
	    my @tmp = split (":", $node->[-1][$i]{tl});
	    for (my $j = $#tmp; $j >= 0; $j--) {
		my @tltmp = split("", $tmp[$j]);
		if ($tltmp[-1] =~ /(a|i|u|e|o)/) {
		    pop (@tltmp);
		    my $newstr = join ("", @tltmp);
		    push (@tmp, $newstr);
		}
	    }
	    my %cand;
	    foreach my $key (@tmp) {
		$cand{$key} = 1;
	    }
	    $node->[$#{$node}][$i]{tl} = join (":", keys %cand);
	}

	my @sum;
	for (my $i = 0; $i <= @estr; $i++) {
	    $sum[0][$i]{score} = $i;
	}

	for (my $node_num = 1; $node_num <= @jstr; $node_num++) {
	    for (my $path = 0; $path < @{$node->[$node_num]}; $path++) {
		if ($node->[$node_num][$path]{tl} eq "" && $#{$node->[$node_num]} == 0) {
		    for (my $j = 0; $j <= @estr; $j++) {
			$sum[$node_num][$j]{score} = $sum[$node->[$node_num][$path]{start}][$j]{score};
			$sum[$node_num][$j]{tl} = "";
			$sum[$node_num][$j]{path} = "1:0";
			$sum[$node_num][$j]{node} = $path;
		    }
		}
		foreach my $key (split(":", $node->[$node_num][$path]{tl})) {
		    my @sub_sum;
		    undef (@sub_sum);
		    for (my $j = 0; $j <= @estr; $j++) {
			$sub_sum[0][$j]{score} = $sum[$node->[$node_num][$path]{start}][$j]{score};
		    }
		    my @sub_jstr = split("", $key);

		    for (my $i = 1; $i <= @sub_jstr; $i++) {
			for (my $j = 0; $j <= @estr; $j++) {
			    my $min_score = 100;
			    my $min_path;

			    # 1文字削除
			    if ($sub_sum[$i-1][$j]{score} + 1 <= $min_score) {
				$min_score = $sub_sum[$i-1][$j]{score} + 1;
				$min_path =  "1:0";
			    }
			    # 1文字挿入
			    if ($j > 0 && $sub_sum[$i][$j-1]{score} + 1 <= $min_score) {
				$min_score = $sub_sum[$i][$j-1]{score} + 1;
				$min_path = "0:1";
			    }
			    # 1vs1置換
			    if ($j > 0) {
				if ($sub_jstr[$i-1] eq $estr[$j-1] && $sub_sum[$i-1][$j-1]{score} <= $min_score) {
					$min_score = $sub_sum[$i-1][$j-1]{score};
					$min_path = "1:1";
				} else {
				    if ($sub_sum[$i-1][$j-1]{score} + 1.5 <= $min_score) {
					$min_score = $sub_sum[$i-1][$j-1]{score} + 1.5;
					$min_path = "1:1";
				    }
				}
				
			    }
			    
			    $sub_sum[$i][$j]{score} = $min_score;
			    $sub_sum[$i][$j]{path} = $min_path;
			}
		    }

		    for (my $j = 0; $j <= @estr; $j++) {
			if (!(defined $sum[$node_num][$j]{score}) || $sum[$node_num][$j]{score} > $sub_sum[@sub_jstr][$j]{score}) {
			    $sum[$node_num][$j]{score} = $sub_sum[@sub_jstr][$j]{score};
			    $sum[$node_num][$j]{tl} = $key;

			    my $now_i_node = @sub_jstr;
			    my $now_j_node = $j;
			    while ($now_i_node != 0) {
				my ($ipath, $jpath) = split(":", $sub_sum[$now_i_node][$now_j_node]{path});
				$now_i_node -= $ipath;
				$now_j_node -= $jpath;
			    }
			    
			    $sum[$node_num][$j]{path} = $node_num - $node->[$node_num][$path]{start} . ":" . ($j - $now_j_node);
			    $sum[$node_num][$j]{node} = $path;
			}
		    }
		}
	    }
	}

	my $now_i_node = $#{$node};
	my $now_j_node = @estr;
	my $tl_str;

	while ($now_i_node != 0) {
	    $tl_str = $sum[$now_i_node][$now_j_node]{tl} . $tl_str;
	    my ($ipath, $jpath) = split(":", $sum[$now_i_node][$now_j_node]{path});
	    $now_i_node -= $ipath;
	    $now_j_node -= $jpath;
	}

	# print "max = $tl_str\n";

 	my $divider;

 	if (length($tl_str) > @estr) {
 	    $divider = @estr * 1.5 + length($tl_str) - @estr;
 	} else {
 	    $divider = length($tl_str) * 1.5 + @estr - length($tl_str);
 	}

 	my $printscore = 1 - $sum[$#{$node}][@estr]{score} / $divider - $penalty * 0.1;
	
	push (@score, $printscore);
    }

     @score = sort {$b <=> $a} @score;
     return $score[0];
}
	
######################################################################

# Modified by Yu, translate English word to Chinese word
sub translate_e2c {
    my ($this, $engWord) = @_;
    $engWord =~ tr/A-Z/a-z/;

    # by NICT
    my $dic_dir = $INC{'TransLiterate.pm'}; # get the path of this pm
    $dic_dir =~ s|/TransLiterate\.pm$||;   # get the directory
    my $ecDict_path = File::Spec->catfile($dic_dir, "ecDict.utf");
    open (DICT, "<:encoding(utf-8)", $ecDict_path) or die "Cannot open '$ecDict_path'";

    my %ecDict;
    my @trans;
    my $key;

    # read english-chinese dictionary
    while (<DICT>) {
	chomp;
	@trans = split("\/");
	$key = $trans[0];
	shift(@trans);
	@{$ecDict{$key}} = @trans;
    }
    close (DICT);

    # check the e-c dictionary, return the first translation if there exists the english word, otherwise return ""
    if (exists($ecDict{$engWord})) {
	return ${$ecDict{$engWord}}[0];
    }
    else {
	return "";
    }
}

1;
