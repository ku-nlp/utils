# coding:utf-8

from pyknp import KNP
import sys


def parseDependency(bnst_list):
    parent_and_child = []  # list of [parent,child]
    for bnst in bnst_list:
        if bnst.parent:
            parent_and_child.append([bnst.parent, bnst])
    dependency = [] 
    for pac in parent_and_child:
        dependent_repname = []
        for bnst in pac:
            dependent_repname.append("".join(mrph.repname for mrph in bnst.mrph_list()))
        dependency.append(dependent_repname)
    return dependency


def test():
    knp = KNP()

    data = u""
    i = 0
    for line in iter(sys.stdin.readline, ""):
        i += 1
        print i
        data += line.strip().replace(":", ",").decode("utf-8")
        if data == u"":
            continue
        result = knp.parse(data)
        DB = parseDependency(result.bnst_list())
        for bnstlist in DB:
            for repname in bnstlist:
                print repname.encode("utf-8"),
            print
        data = u""

if __name__ == "__main__":
    test()
