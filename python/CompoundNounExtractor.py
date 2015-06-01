# -*-coding: utf-8 -*-
from pyknp import KNP
import sys
import codecs

sys.stdin  = codecs.getreader('UTF-8')(sys.stdin)
sys.stdout = codecs.getwriter('UTF-8')(sys.stdout)
sys.stderr = codecs.getwriter('UTF-8')(sys.stderr)

def CheckConditionMid(midasi,fstring,hinsi):
    return any(fstr in fstring for fstr in (u'名詞相当語',u'漢字',u'独立タグ接頭辞',u'複合'))
    
def CheckConditionHead(midasi,fstring,hinsi):
    return any(fstr in fstring for fstr in (u'名詞相当語',u'漢字',u'独立タグ接頭辞'))
    
def CheckConditionTail(midasi,fstring,hinsi):
    return any(fstr in fstring for fstr in (u'名詞相当語',u'かな漢字',u'カタカナ'))
    
def ExtractCompoundNounfromBnst(bnst):
    num_of_mrph = len(bnst.mrph_list())
    is_ok_for_mid = []
    is_ok_for_head = []
    is_ok_for_tail = []
    cmp_noun_list = []
    
    for mrph in bnst.mrph_list():
        midasi = mrph.midasi
        fstring = mrph.fstring
        hinsi = mrph.hinsi
        
        is_ok_for_mid.append( (CheckConditionMid(midasi,fstring,hinsi), midasi) )
        is_ok_for_head.append( (CheckConditionHead(midasi,fstring,hinsi), midasi) )
        is_ok_for_tail.append( (CheckConditionTail(midasi,fstring,hinsi), midasi) )

    for i in xrange(num_of_mrph - 1, -1, -1):
        cmp_noun = u''
        if is_ok_for_tail[i][0]:
            cmp_noun += is_ok_for_tail[i][1]
            for j in xrange(i - 1, -1, -1):
                if is_ok_for_head[j][0]:
                    cmp_noun = is_ok_for_head[j][1] + cmp_noun
                    cmp_noun_list.append(cmp_noun)
                if not is_ok_for_mid[j][0]:
                    break

    for noun in cmp_noun_list:
        print noun

if __name__ == '__main__':
    knp = KNP()
    data = u""

    for line in iter(sys.stdin.readline,u""):
        data += line
        if line.strip() == u"EOS":
            result = knp.result(data)
            flag = 0
            cmp_noun_list = []
            cmp_noun = u""
            for bnst in result.bnst_list():
                cmp_noun_list = ExtractCompoundNounfromBnst(bnst)


                
