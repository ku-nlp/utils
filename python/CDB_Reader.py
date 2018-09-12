# -*- coding: utf-8 -*-
from __future__ import print_function
from __future__ import division
import re
import sys
import os
import codecs
from pycdb import CDB


class CDB_Reader:
    def __init__(self, keyMapFile, repeated_keys=False, numerical_keys=True,
                 encoding='utf-8'):
        # whether multiple values exists for one key
        self.repeated_keys = repeated_keys
        self.numerical_keys = numerical_keys
        self.mapping = []
        self.encoding = encoding

        dbdir = os.path.dirname(keyMapFile)        # remove basename
        basename = os.path.basename(keyMapFile)    # keyMapFile without dbdir
        basename = re.sub("keymap", "", basename)  # remove "keymap" from basename

        CDB0 = "{}/{}{}".format(dbdir, basename, "0")
        if os.path.isfile(CDB0):
            self.mapping.append({'key': None, 'cdb': CDB0})

        # check for validity
        if os.path.isfile(keyMapFile):
            CDB1 = "{}/{}{}".format(dbdir, basename, "1")
            if os.path.isfile(CDB1) and os.path.getsize(keyMapFile) <= 0:
                print("The size of the keymapfile is 0, but {} \
                exists. The size of the keymapfile should be more than 0!\n"
                                 .format(CDB1), file=sys.stderr)
                sys.exit(1)
        else:
            print("{} doesn't exist!".format(keyMapFile), file=sys.stderr)
            sys.exit(1)

        # parse the keymap file.
        with codecs.open(keyMapFile, 'r', self.encoding) as f:
            kvptn = re.compile(r"^(.+) ([^ ]+)$")
            for line in iter(f.readline, ''):
                line = line.strip()
                if kvptn.match(line):
                    key, which_file = kvptn.match(line).groups()
                else:
                    print("malformed keymap.\n", file=sys.stderr)
                    sys.exit(1)
                CDBi = "{}/{}".format(dbdir, which_file)
                if os.path.isfile(CDBi):
                    self.mapping.append({'key': key, 'cdb': CDBi})
                else:
                    sys.exit(1)

    def _getall_cdb(self, cdb, key):
        cdb_cursor = cdb.findstart()
        values = []
        while cdb_cursor.findnext(key):
            values.append(cdb_cursor.read())
        return values

    def get(self, searchKey, exhaustive=False):
        # exhaustive must be True if keys are not sorted in ascending order
        if exhaustive:
            values = []  # valid when repeated_keys is True
            for i in range(len(self.mapping)):
                nowCDB = self.mapping[i]['cdb']
                targetCDB = CDB(open(nowCDB, 'rb'), encoding=self.encoding)
                if self.repeated_keys:
                    values += self._getall_cdb(targetCDB, searchKey)
                else:
                    value = None
                    try:
                        value = targetCDB[searchKey]
                    except KeyError:
                        pass
                    if value is not None:
                        return value
            if self.repeated_keys and values:
                return values
            else:
                return None
        else:
            nowCDB = self.mapping[0]['cdb']
            i = 0
            for i in range(1, len(self.mapping)):
                nowKey = self.mapping[i]['key']
                if self.numerical_keys:
                    if int(searchKey) < int(nowKey):
                        break
                else:
                    if searchKey < nowKey:
                        break
                nowCDB = self.mapping[i]['cdb']
            targetCDB = CDB(open(nowCDB, 'rb'), encoding=self.encoding)
            if self.repeated_keys:
                value = self._getall_cdb(targetCDB, searchKey)
                # in case searchKey extends over two files
                if nowCDB != self.mapping[i]['cdb']:
                    i -= 1
                if i - 1 >= 0:
                    nowCDB = self.mapping[i - 1]['cdb']
                    targetCDB = CDB(open(nowCDB, 'rb'), encoding=self.encoding)
                    value += self._getall_cdb(targetCDB, searchKey)
            else:
                value = None
                try:
                    value = targetCDB[searchKey]
                except KeyError:
                    pass
            return value


if __name__ == "__main__":
    pass
