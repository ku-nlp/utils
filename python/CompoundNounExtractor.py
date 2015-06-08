# -*-coding: utf-8 -*-

from pyknp import KNP
import sys
import codecs
import re
from optparse import OptionParser

def CheckConditionMid(midasi,fstring,bunrui,hinsi):
    """ 真ん中に来れるかどうかをチェック """
    fstr_flag =  any(fstr in fstring for fstr in (u'名詞相当語',u'漢字',u'独立タグ接頭辞',u'複合'))
    if fstr_flag:
        bunrui_flag = any(bnr in bunrui for bnr in (u'副詞的名詞',u'形式名詞'))
        fstr_num_flag = (u'記号' in fstring)
        return (not bunrui_flag) and (not fstr_num_flag)
    else:
        return False
    
def CheckConditionHead(midasi,fstring,hinsi):
    """ 先頭に来れるかどうかをチェック """
    
    # "接尾辞"の条件は「-性海棉状脳症」などを除くため
    if (re.search(ur"<(?:名詞相当語|漢字)>", fstring) or hinsi != u"接頭辞") and hinsi != u"接尾辞":
        return True
    else:
        return False
    
def CheckConditionTail(midasi,fstring,bunrui,hinsi):
    """ 最後に来れるかどうかをチェック """
    fstr_flag0 =  any(fstr in fstring for fstr in (u'名詞相当語',u'かな漢字',u'カタカナ'))
    if fstr_flag0:
        hiragana_flag = (u'あ' <= midasi <= u'ん')
        bunrui_flag = any(bnr in bunrui for bnr in (u'副詞的名詞',u'形式名詞'))
        fstr_flag1 = any(fstr in fstring for fstr in (u'記号',u'数字'))
        fstr_flag2 = (u'非独立タグ接尾辞' in fstring) and not (u'意味有' in fstring)
        hinsi_flag = (hinsi == u'接頭辞')
        return (not hiragana_flag) and (not bunrui_flag) and (not fstr_flag1) and (not fstr_flag2) and (not hinsi_flag)
    else:
        return False
    
def ExtractCompoundNounfromBnst(bnst, longest = False):
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

            if not is_ok_for_head[j]:
                continue

            word_list.append({ "midasi":midasi })
            outputted_flag = 1

        if longest:
            return word_list[-1]
        
        if len(word_list) > 0:
            ret_word_list.extend(word_list)
            
    return ret_word_list

if __name__ == "__main__":
    sys.stdin  = codecs.getreader('UTF-8')(sys.stdin)
    sys.stdout = codecs.getwriter('UTF-8')(sys.stdout)
    sys.stderr = codecs.getwriter('UTF-8')(sys.stderr)

    parser = OptionParser()
    parser.add_option(
        '-l', '--longest',
        action = 'store_true',
        dest = 'longest'
        )

    options, args = parser.parse_args()
    
    knp = KNP()
    data = u""

    for line in iter(sys.stdin.readline,u""):
        data += line
        if line.strip() == u"EOS":
            result = knp.result(data)
            for bnst in result.bnst_list():
                print u"★ bid:%s" % bnst.bnst_id
                if options.longest:
                    word = ExtractCompoundNounfromBnst(bnst, longest=1)
                    if len(word) > 0:
                        print word["midasi"]
                    print
                else:
                    words = ExtractCompoundNounfromBnst(bnst)
                    for word in words:
                        print word["midasi"]
                    print
