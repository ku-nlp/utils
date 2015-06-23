# coding:utf-8

from pyknp import KNP
import sys
from CompoundNounExtractor import CompoundNounExtractor


def extract_head(cn_list, head, bnst):
    Compflag = False
    for cn in cn_list:
        for mrph in bnst.mrph_list():
            if mrph.hinsi != u"名詞":
                if (mrph.repname not in head):
                    head.append(mrph.repname)
                continue
            if mrph.midasi in cn:
                if Compflag:
                    head.pop(-1)
                    head.append(mrph.repname)
                else:
                    Compflag = True
                    head.append(mrph.repname)
    
    return "".join(head)


# bnst_list内の係り受け関係のある文節を"親文節-子文節"の形式のリストにして出力
def parseDependency(bnst_list, head=False):
    parent_child = []
    
    # 文節の代表表記
    if head is False:
        for bnst in bnst_list:
            if bnst.parent:
                parent_child.append("-".join([bnst.parent.repname, bnst.repname]))

    # 複合名詞の主辞だけを取り出す
    elif head is True:
        cne = CompoundNounExtractor()
        cn_list = []
        # 最長一致の複合名詞を要素とするリストを作る
        for bnst in bnst_list:
            comp_noun_list_of_dictionary = cne.ExtractCompoundNounfromBnst(bnst,
                                                                           longest=True,
                                                                           use_repname=True)
            if comp_noun_list_of_dictionary != []:
                for comp_noun in comp_noun_list_of_dictionary:
                    if comp_noun and comp_noun["midasi"] not in cn_list:
                        print comp_noun["midasi"]
                        cn_list.append(comp_noun["midasi"])
        # 分節内の形態素で複合名詞の一部となる名詞があれば複合名詞の最後の名詞だけ抽出
        for bnst in bnst_list:
            parent = []
            child = []
            if bnst.parent:
                # 子文節について
                child_rep = extract_head(cn_list, child, bnst)
                # 親文節について
                parent_rep = extract_head(cn_list, parent, bnst.parent)
            if "-".join([parent_rep, child_rep]) not in parent_child:
                parent_child.append("-".join([parent_rep, child_rep]))

    return parent_child


def test():
    # ex.)echo "私は自然言語処理の研究をする"  | juman | knp -tab -dpnd | python DependencyParser.py

    import codecs
    sys.stdin  = codecs.getreader('UTF-8')(sys.stdin)
    sys.stdout = codecs.getwriter('UTF-8')(sys.stdout)
    sys.stderr = codecs.getwriter('UTF-8')(sys.stderr)

    knp = KNP()
    data = u""

    for line in iter(sys.stdin.readline, ""):
        data += line
        if line.strip() == u"EOS":
            result = knp.result(data)
            DB = parseDependency(result.bnst_list(), head=False)
            DBhead = parseDependency(result.bnst_list(), head=True)
            print "parent-child"
            # for bnstrep in DB:
                # print bnstrep
            for bnstrep in DBhead:
                print bnstrep
            data = u""

if __name__ == "__main__":
    test()
