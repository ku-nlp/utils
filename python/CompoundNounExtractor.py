# -*-coding: utf-8 -*-

def CheckConditionMid(midasi,fstring,bunrui,hinsi):
    fstr_flag =  any(fstr in fstring for fstr in (u'名詞相当語',u'漢字',u'独立タグ接頭辞',u'複合'))
    if fstr_flag:
        bunrui_flag = any(bnr in bunrui for bnr in (u'副詞的名詞',u'形式名詞'))
        fstr_num_flag = (u'記号' in fstring)
        return (not bunrui_flag) and (not fstr_num_flag)
    else:
        return False
    
def CheckConditionHead(midasi,fstring,hinsi):
    fstr_flag =  any(fstr in fstring for fstr in (u'名詞相当語',u'漢字',u'独立タグ接頭辞'))
    if fstr_flag:
        return not (hinsi == u'接尾辞')
    else:
        return False
    
def CheckConditionTail(midasi,fstring,bunrui,hinsi):
    fstr_flag0 =  any(fstr in fstring for fstr in (u'名詞相当語',u'かな漢字',u'カタカナ'))
    if fstr_flag0:
        hiragana = (u'あ' <= midasi <= u'ん')
        bunrui_flag = any(bnr in bunrui for bnr in (u'副詞的名詞',u'形式名詞'))
        fstr_flag1 = any(fstr in fstring for fstr in (u'記号',u'数字'))
        fstr_flag2 = (u'非独立タグ接尾辞' in fstring) and not (u'意味有' in fstring)
        return (not hiragana) and (not bunrui_flag) and (not fstr_flag1) and (not fstr_flag2)
    else:
        return False
    
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
        bunrui = mrph.bunrui
        
        is_ok_for_mid.append( (CheckConditionMid(midasi,fstring,bunrui,hinsi), midasi) )
        is_ok_for_head.append( (CheckConditionHead(midasi,fstring,hinsi), midasi) )
        is_ok_for_tail.append( (CheckConditionTail(midasi,fstring,bunrui,hinsi), midasi) )

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

    return cmp_noun_list
