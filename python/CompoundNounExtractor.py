# -*-coding: utf-8 -*-

# 複合名詞を抽出する
# ex.)
# % echo "私は自然言語処理の研究をする" | juman | knp -tab -dpnd | python CompoundNounExtractor.py
# %
# ★ bid0
# repname:私/わたし

# ★ bid1
# repname:処理/しょり

# repname:言語/げんご+処理/しょり

# repname:自然/しぜんa+言語/げんご+処理/しょり

# repname:言語/げんご

# repname:自然/しぜんa+言語/げんご

# repname:自然/しぜんa

# ★ bid2
# repname:研究/けんきゅう

# ★ bid3

# 研究

# モジュールとして
# ex.)
# for bnst in bnst_list():
#     words = CNE.ExtractCompoundNounfromBnst(bnst, longest=True, repname=True)
#     for word in words:
#         print word

import re
from argparse import ArgumentParser


class CompoundNounExtractor(object):
    def get_args(self):
        usage = u'{0} [Args] [Options]\nDetailed options -h or --help'.format(__file__)
        parser = ArgumentParser(description=usage)

        parser.add_argument(
            '-l', '--longest',
            action='store_true',
            dest='longest',
            help='return only the longest compound noun')
        parser.add_argument(
            '-r', '--repname',
            action='store_true',
            dest='repname',
            help='return repname')

        self.args = parser.parse_args()

    def CheckConditionMid(self, midasi, fstring, bunrui, hinsi):
        """ 真ん中に来れるかどうかをチェック """
        if (re.search(ur"<(?:名詞相当語|漢字|複合←)>", fstring) is None and hinsi != u"接頭辞") or \
           re.search(ur"<記号>", fstring) or \
           re.search(ur"(?:副詞的|形式)名詞", bunrui) or \
           re.search(ur"・・", fstring):
            return False
        else:
            return True

    def CheckConditionHead(self, midasi, fstring, hinsi):
        """ 先頭に来れるかどうかをチェック """

        # "接尾辞"の条件は「-性海棉状脳症」などを除くため
        if (re.search(ur"<(?:名詞相当語|漢字)>", fstring) or hinsi == u"接頭辞") and \
           hinsi != u"接尾辞" and \
           not re.search(ur"(?:・|っ|ぁ|ぃ|ぅ|ぇ|ぉ|ゃ|ゅ|ょ)", midasi):
            return True
        else:
            return False

    def CheckConditionTail(self, midasi, fstring, bunrui, hinsi):
        """ 最後に来れるかどうかをチェック """

        # ひらがな一文字(接尾辞と接頭辞を除く)
        # 一番最後が名詞でない
        # 形式名詞（もの, こと..)/副詞的名詞(よう, とき..)
        # 名詞相当語 かつ 記号 .. ●,《, ＠など
        # 「イースター島再来訪」から「イースター島再」を排除
        if ((u'あ' <= midasi <= u'ん') and re.search(ur"(?:接頭辞|接尾辞)", hinsi) is None) or \
           re.search(ur"<(?:名詞相当語|かな漢字|カタカナ)>", fstring) is None or \
           re.search(ur"(?:副詞的|形式)名詞", bunrui) or \
           re.search(ur"<記号>", fstring) or \
           hinsi == u"接頭辞" or \
           re.search(ur"・・", midasi):
            return False
        else:
            return True

    def ExtractCompoundNounfromBnst(self, bnst, longest=False, use_repname=False):
        self.is_ok_for_mid = []
        self.is_ok_for_head = []
        self.is_ok_for_tail = []
        self.ret_word_list = []
        num_of_mrph = len(bnst.mrph_list())

        for mrph in bnst.mrph_list():
            midasi = mrph.midasi
            fstring = mrph.fstring
            hinsi = mrph.hinsi
            bunrui = mrph.bunrui

            self.is_ok_for_mid.append(self.CheckConditionMid(midasi, fstring, bunrui, hinsi))
            self.is_ok_for_head.append(self.CheckConditionHead(midasi, fstring, hinsi))
            self.is_ok_for_tail.append(self.CheckConditionTail(midasi, fstring, bunrui, hinsi))

        # ループを回して複合名詞を探す。
        #
        # ex) 自然 言語 処理 と は、
        #           j    i
        longest_tail_flag = 0
        outputted_flag = 0
        for i in xrange(num_of_mrph - 1, -1, -1):
            word_list = []
            midasi = ""
            repname = ""

            if not self.is_ok_for_tail[i]:
                longest_tail_flag = 0
                outputted_flag = 0
                continue

            longest_tail_flag += 1

            for j in xrange(i, -1, -1):
                if not self.is_ok_for_mid[j]:
                    break

                midasi_j = bnst.mrph_list()[j].midasi
                midasi = midasi_j + midasi
                repname_j = bnst.mrph_list()[j].repname
                repname = repname_j + "+" + repname

                if not self.is_ok_for_head[j]:
                    continue
                word_list.append({"midasi": midasi, "repname": repname[:-1]})
                outputted_flag = 1

            if longest and outputted_flag:
                return [word_list[-1]]

            if len(word_list) > 0:
                self.ret_word_list.extend(word_list)

        return self.ret_word_list


if __name__ == "__main__":
    from pyknp import KNP
    import sys
    import codecs
    
    sys.stdin = codecs.getreader('UTF-8')(sys.stdin)
    sys.stdout = codecs.getwriter('UTF-8')(sys.stdout)
    sys.stderr = codecs.getwriter('UTF-8')(sys.stderr)

    CNE = CompoundNounExtractor()
    CNE.get_args()

    knp = KNP()
    data = ""

    for line in iter(sys.stdin.readline, ""):
        data += line
        if line.strip() == "EOS":
            result = knp.result(data)
            for bnst in result.bnst_list():
                print u"★ bid%d" % int(bnst.bnst_id)
                words = CNE.ExtractCompoundNounfromBnst(bnst,
                                                    longest=CNE.args.longest,
                                                    use_repname=CNE.args.repname)
                if words == []:
                    continue
                if not CNE.args.repname:
                    for word in words:
                        print u"midasi:%s repname:%s\n" \
                            % (word["midasi"], word["repname"])
                else:
                    for word in words:
                        print u"repname:%s\n" % word["repname"]

