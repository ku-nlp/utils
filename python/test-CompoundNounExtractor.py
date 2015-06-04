# -*-coding: utf-8 -*-
from pyknp import KNP
import sys
import codecs
from CompoundNounExtractor import *

sys.stdin  = codecs.getreader('UTF-8')(sys.stdin)
sys.stdout = codecs.getwriter('UTF-8')(sys.stdout)
sys.stderr = codecs.getwriter('UTF-8')(sys.stderr)

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
                for cmp_noun in cmp_noun_list:
                    print cmp_noun
