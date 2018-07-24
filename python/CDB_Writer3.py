# CDB_Writer for Python3.x
#
# This script uses pycdb instead of python-cdb
# because python-cdb is not compatible with Python3

# -*-coding: utf-8 -*-
import os
import codecs
from pycdb import CDBMake

LFS_DEFAULT = 2.5 * (1024**3)  # 2.5GB(file)-> about 2.6GB(cdb)


class CDB_Writer:
    def __init__(self, dbname, keyMapFile, limit_file_size=LFS_DEFAULT,
                 fetch=1000000, encoding='utf-8'):
        # the options.
        self.dbname = dbname
        # used by CDB_Reader to decide which cdb includes the query key
        self.keyMapFile = keyMapFile
        self.limit_file_size = limit_file_size
        # determines how often to check if current cdb size exceeds the limit
        self.fetch = fetch
        self.num_of_cdbs = 0
        self.encoding = encoding
        self.size = 0

        dbname = "{}.{}".format(self.dbname, self.num_of_cdbs)
        print("processing {}".format(dbname))
        self.cdb = CDBMake(open(dbname, 'wb'), encoding=self.encoding)
        dbdir = os.path.dirname(self.dbname)
        keyMapPath = "{}/{}".format(dbdir, keyMapFile)
        self.keymap = codecs.open(keyMapPath, 'w', self.encoding)

    def __del__(self):
        self.cdb.finish()
        self.keymap.close()

    def add(self, key, value):
        if self.size > self.limit_file_size:
            # この時keyが前回のaddのkeyと同じだった場合、前回のvalueにはアクセスできなくなる
            self.cdb.finish()
            self.num_of_cdbs += 1

            dbnamei = "{}.{}".format(self.dbname, self.num_of_cdbs)
            print("processing {}".format(dbnamei))
            dbnamei_tmp = dbnamei + ".tmp"
            self.tmpfile = dbnamei_tmp
            self.cdb = CDBMake(open(dbnamei, 'wb'), encoding=self.encoding)

            # save head keys of each splitted cdbs
            filebase = os.path.basename(dbnamei)
            self.keymap.write("{} {}\n".format(key, filebase))
            self.size = 0

        key_str, value_str = str(key), str(value)
        self.cdb.add(key_str, value_str)
        self.size += len(codecs.encode(key_str)) + len(codecs.encode(value_str))
