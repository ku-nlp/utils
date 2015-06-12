# -*-coding: utf-8 -*-

from pyknp import KNP
import sys
import codecs
import re
from optparse import OptionParser
from argparse import ArgumentParser

def CheckConditionMid(midasi,fstring,bunrui,hinsi):
    """ 真ん中に来れるかどうかをチェック """

    if re.search(ur"<(?:名詞相当語|漢字|複合←)>", fstring) is None and hinsi != u"接頭辞" or \
        re.search(ur"<記号>", fstring) or \
        re.search(ur"(?:副詞的|形式)名詞", bunrui):
        return False
    else:
        return True
    
def CheckConditionHead(midasi,fstring,hinsi):
    """ 先頭に来れるかどうかをチェック """
    
    # "接尾辞"の条件は「-性海棉状脳症」などを除くため
    if (re.search(ur"<(?:名詞相当語|漢字)>", fstring) or hinsi == u"接頭辞") and hinsi != u"接尾辞":
        return True
    else:
        return False
    
def CheckConditionTail(midasi,fstring,bunrui,hinsi):
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
        hinsi == u"接頭辞":
        return False
    else:
        return True
    
def ExtractCompoundNounfromBnst(bnst, longest = False, use_repname = False):
    num_of_mrph = len( bnst.mrph_list() )
    is_ok_for_mid = []
    is_ok_for_head = []
    is_ok_for_tail = []
    ret_word_list = []
    
    for mrph in bnst.mrph_list():
        midasi = mrph.midasi
        fstring = mrph.fstring
        hinsi = mrph.hinsi
        bunrui = mrph.bunrui
        
        is_ok_for_mid.append(CheckConditionMid(midasi,fstring,bunrui,hinsi))
        is_ok_for_head.append(CheckConditionHead(midasi,fstring,hinsi))
        is_ok_for_tail.append(CheckConditionTail(midasi,fstring,bunrui,hinsi))

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
        
        if not is_ok_for_tail[i]:
            longest_tail_flag = 0
            outputted_flag = 0
            continue

        longest_tail_flag += 1
        
        for j in xrange(i, -1, -1):
            if not is_ok_for_mid[j]:
                break

            midasi_j = bnst.mrph_list()[j].midasi
            midasi = midasi_j + midasi
            if use_repname:
                repname_j = bnst.mrph_list()[j].repname
                repname = repname_j + repname

            if not is_ok_for_head[j]:
                continue

            word_list.append({ "midasi": midasi, "repname": repname })
            outputted_flag = 1

        if longest and outputted_flag:
            return [ word_list[-1] ]
        
        if len(word_list) > 0:
            ret_word_list.extend(word_list)
            
    return ret_word_list

if __name__ == "__main__":
    sys.stdin  = codecs.getreader('UTF-8')(sys.stdin)
    sys.stdout = codecs.getwriter('UTF-8')(sys.stdout)
    sys.stderr = codecs.getwriter('UTF-8')(sys.stderr)

    usage = u'{0} [Args] [Options]\nDetailed options -h or --help'.format(__file__)
    parser = ArgumentParser( description = usage )
    parser.add_argument(
        '-l', '--longest',
        action = 'store_true',
        dest = 'longest',
        help = 'return only the longest compound noun'
        )
    parser.add_argument(
        '-r', '--repname',
        action = 'store_true',
        dest = 'repname',
        help = 'return repname'
        )

    args = parser.parse_args()

    
    knp = KNP()
    data = ""

    for line in iter( sys.stdin.readline, ""):
        data += line
        if line.strip() == u"EOS":
            result = knp.result(data)
            for bnst in result.bnst_list():
                print u"★ bid:%s" % bnst.bnst_id
                if args.longest:
                    word = ExtractCompoundNounfromBnst( bnst, longest = True,\
                                                        use_repname = args.repname )
                    if len(word) > 0:
                        if not args.repname:
                            print word[ "midasi" ]
                        else:
                            print word[ "repname" ]
                    print
                else:
                    words = ExtractCompoundNounfromBnst( bnst,\
                                                         use_repname = args.repname )
                    if args.repname == False:
                        for word in words:
                            print word[ "midasi" ]
                    else:
                        for word in words:
                            print word[ "repname" ]
                    print
