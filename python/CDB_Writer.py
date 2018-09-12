# -*- coding: utf-8 -*-
from __future__ import print_function
import os
import codecs
from pycdb import CDBMake

LFS_DEFAULT = 3.2 * (1024**3)  # Actual file size is larger than this value


class CDB_Writer:
    def __init__(self, dbname, keyMapFile, limit_file_size=LFS_DEFAULT,
                 encoding='utf-8'):
        # the options.
        self.dbname = dbname
        # used by CDB_Reader to decide which cdb includes the query key
        self.keyMapFile = keyMapFile
        self.limit_file_size = limit_file_size
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
        del self.cdb
        self.keymap.close()

    def add(self, key, value):
        if self.size > self.limit_file_size:
            self.cdb.finish()
            self.num_of_cdbs += 1

            dbnamei = "{}.{}".format(self.dbname, self.num_of_cdbs)
            print("processing {}".format(dbnamei))
            self.cdb = CDBMake(open(dbnamei, 'wb'), encoding=self.encoding)

            # save head keys of each splitted cdbs
            filebase = os.path.basename(dbnamei)
            self.keymap.write("{} {}\n".format(key, filebase))
            self.size = 0

        key_str, value_str = str(key), str(value)
        self.cdb.add(key_str, value_str)
        self.size += (len(key_str.encode('utf-8'))
        + len(value_str.encode('utf-8')))


if __name__ == '__main__':
    pass
