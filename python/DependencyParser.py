# coding:utf-8

from pyknp import KNP
import sys
import codecs


# bnst_list内の係り受け関係のある文節を"親文節-子文節"の形式のリストにして出力
def parseDependency(bnst_list):
    parent_child = []
    for bnst in bnst_list:
        if bnst.parent:
            parent_child.append("-".join([bnst.parent.repname, bnst.repname]))
    return parent_child


def test():
    # ex.)echo "私は自然言語処理の研究をする"  | juman | knp -tab -dpnd | python DependencyParser.py
    sys.stdin  = codecs.getreader('UTF-8')(sys.stdin)
    sys.stdout = codecs.getwriter('UTF-8')(sys.stdout)
    sys.stderr = codecs.getwriter('UTF-8')(sys.stderr)
    
    knp = KNP()
    data = u""

    for line in iter(sys.stdin.readline, ""):
        data += line
        if line.strip() == u"EOS":
            result = knp.result(data)
            DB = parseDependency(result.bnst_list())
            print "parent-child"
            for bnstrep in DB:
                print bnstrep
                data = u""

if __name__ == "__main__":
    test()
