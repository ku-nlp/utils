#!/usr/bin/env python
# -*-coding: utf-8 -*-

import sys
import io
import argparse
import re
import regex
from pyknp import KNP

KEY2ATTRIBUTE = { "品詞": "hinsi", "原形": "genkei", "分類": "bunrui", "活用": "katuyou2" }
KEYS_STRING = "|".join(KEY2ATTRIBUTE.keys())
tag_pat_compiled = re.compile(r"<({}):(.+?)>".format(KEYS_STRING))

CHARTYPE2UNICODE = { "ひらがな": "InHiragana", "カタカナ": "InKatakana", "漢字": "Han", "英数字": "Latin" }
CHARTYPES_STRING = "|".join(CHARTYPE2UNICODE.keys())
char_pat_compiled = re.compile(r"<字種:({})>".format(CHARTYPES_STRING))

class Rule(object):
    def __init__(self):
        self.patterns = None
        self.pattern_num = None
        self.line = ""
        self.mark_start = -1
        self.mark_end = -1
        self.whole_match = False
        
class MrphSeqMatch(object):
    def __init__(self, rule_file):
        self.rule_file = rule_file

        self.rules = self.read_rule()

    def mrph_seq_match(self, result):
        mrph_num = len(result.mrph_list())
        for rule in self.rules:
            for j in reversed(range(mrph_num)):
                if rule.whole_match is True and j != 0:
                    continue

                flag = True
                flag_s = True
                split_num = 0
                for k in range(rule.pattern_num):
                    # マッチしない場合、flagを下げて次の形態素へ
                    
                    # sが最後についているパターンはそのパターンと前のパターンの間に
                    # 任意のパターンの形態素が入ることを示す
                    if rule.patterns[k].endswith("s") is True:
                        flag_s = False

                    if j + k + split_num >= mrph_num or \
                       self.mrph_match(result, rule.patterns[k], j + k + split_num) is False:
                        flag = False
                        break

                    if flag_s is False:
                        split_num += 1
                        k -= 1

                if flag is True and flag_s is True and \
                   ((rule.whole_match is True and j + rule.pattern_num == mrph_num) or rule.whole_match is False):
                    if rule.whole_match is True:
                        return True
                    else:
                        return False

        return False
    
    def mrph_match(self, result, pat, mrph_num):
        if pat.endswith("s"):
            pat.rstrip("s")

        # ^ と < を区切りにし，先頭，重複を削除
        pat = pat.replace("<", " <")
        pat = re.sub(r"\^", " \^", pat)
        pat = re.sub(r"^ <", "<", pat)
        pat = re.sub(r"^ \^", "\^", pat)
        pat = re.sub(r"\^ <", "\^<", pat)

        for p in re.split(" +", pat):
            if p.startswith("^") is True:
                p = p.lstrip("^")
                neg_flag = True
            else:
                neg_flag = False

            match_flag = self.check_pattern_tag(result, p, mrph_num)
            if match_flag == neg_flag:
                return False

        return True

    def check_pattern_tag(self, result, p, m_num):
        """ パターンと照合するかチェック """

        # 例: <品詞:(名詞|形容詞)>
        tag_m = tag_pat_compiled.match(p)
        # 例: <字種:ひらがな>
        char_m = char_pat_compiled.match(p)
        
        if tag_m is not None:
            # 例: 品詞
            key = tag_m.group(1)
            # 例: (名詞|形容詞)
            value = tag_m.group(2)
            
            if re.search(r"^{}$".format(value), getattr((result.mrph_list())[m_num], KEY2ATTRIBUTE[key])):
                return True
        # 字種
        elif char_m is not None:
            char_type = char_m.group(1)
                  
            if regex.search(r"^\p{{{}}}+$".format(CHARTYPE2UNICODE[char_type]), (result.mrph_list())[m_num].midasi):
                return True
        elif p == ".":
            return True
        else:
            if p == (result.mrph_list())[m_num].midasi:
                return True

        return False
    
    def read_rule(self):
        # 一行が1ルール
        # ルールファイルには以下の2とおりがある
        # 
        # 1. 左辺がマッチしたら右辺の情報を付与
        # 例: 「〜しており」にマッチすれば、(マッチした形態素に)「PositiveCand」というFeatureを付与
        # <品詞:動詞><活用:タ系連用テ形> おり -> PositiveCand
        #
        # 2. 全体がマッチするかどうか
        # 例: 「二人組」にマッチ
        # <分類:数詞> <品詞:接尾辞> <品詞:(名詞|接尾辞)>

        with open(self.rule_file, mode="r", encoding="utf-8") as f:
            rules = []
            
            for line in f:
                line = line.strip()
                if line == "" or line.startswith("#") is True:
                    continue

                rules.append(Rule())
                if " -> " in line:
                    raise NotImplementedError()
                else:
                    pattern = line
                    rules[-1].whole_match = True

                rules[-1].patterns = re.split(" +", pattern)
                rules[-1].pattern_num = len(rules[-1].patterns)
                rules[-1].line = line
                
                for i, pat in enumerate(rules[-1].patterns):
                    if pat.endswith("n") is True:
                        pat.rstrip("n")
                    else:
                        if rules[-1].mark_start == -1:
                            rules[-1].mark_start = i
                        rules[-1].mark_end = i

            return rules
    
if __name__ == "__main__":
    sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8')
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

    parser = argparse.ArgumentParser()
    parser.add_argument("--rule_file", dest='rule_file', type=str, action='store', required=True)
    parser.add_argument("--sentence", dest='sentence', type=str, action='store', required=True)
    parser.add_argument("--juman_command", dest='sentence', type=str, action='store', default="/mnt/violet/share/tool/juman++v2/bin/jumanpp")
    args = parser.parse_args()
    
    mrph_seq_match = MrphSeqMatch(args.rule_file)

    knp = KNP(jumancommand=args.jumancommand, option="-tab -dpnd")
    result = knp.parse(args.sentence)
    
    flag = mrph_seq_match.mrph_seq_match(result)
    print(flag)
    
