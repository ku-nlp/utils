# -*-coding: utf-8 -*-
import re
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import os
import codecs
import cdb


class CDB_Reader(object):
    def __init__(self, keyMapFile, repeated_keys=False, numerical_keys=True,
                 encoding='utf-8'):
        # the options.
        self.repeated_keys = repeated_keys
        self.numerical_keys = numerical_keys
        self.mapping = []
        self.encoding = encoding

        dbdir = os.path.dirname(keyMapFile)
        basename = os.path.basename(keyMapFile)
        basename = re.sub("keymap", "", basename)

        CDB0 = "{}/{}{}".format(dbdir, basename, "0")
        if os.path.isfile(CDB0):
            self.mapping.append({'key': None, 'cdb': CDB0})

        # check for validity
        if os.path.isfile(keyMapFile) and os.path.getsize(keyMapFile) > 0:
            CDB1 = "{}/{}{}".format(dbdir, basename, "1")
            if not os.path.isfile(CDB1):
                sys.stderr.write("The size of the keymapfile is 0, but %s \
                exists. The size of the keymapfile should be more than 0!\n"
                                 % (CDB1))
                sys.exit(1)

        # parse the keymap file.
        with codecs.open(keyMapFile, 'r', self.encoding) as f:
            kvptn = re.compile(r"^(.+) ([^ ]+)$")
            for line in iter(f.readline, ''):
                line = line.strip()
                if kvptn.match(line):
                    key, which_file = kvptn.match(line).groups()
                else:
                    sys.stderr.write("malformed keymap.\n")
                    sys.exit(1)
                CDBi = str("{}/{}".format(dbdir, which_file))
                if os.path.isfile(CDBi):
                    self.mapping.append({'key': key, 'cdb': CDBi})
                else:
                    sys.exit(1)

    def get(self, searchKey, exhaustive=False):
        # exhaustive must be True if keys are not sorted in ascending order
        searchKey = searchKey.encode(self.encoding)
        if exhaustive:
            for i in range(len(self.mapping)):
                nowCDB = self.mapping[i]['cdb']
                targetCDB = cdb.init(nowCDB)
                if self.repeated_keys:
                    value = targetCDB.getall(searchKey)
                else:
                    value = targetCDB.get(searchKey)
                if value:
                    return value
            return None
        else:
            nowCDB = self.mapping[0]['cdb']
            for i in range(1, len(self.mapping)):
                nowKey = self.mapping[i]['key']
                if self.numerical_keys:
                    if int(searchKey) < int(nowKey):
                        break
                else:
                    if searchKey < nowKey:
                        break
                nowCDB = self.mapping[i]['cdb']
            targetCDB = cdb.init(nowCDB)
            if self.repeated_keys:
                value = targetCDB.getall(searchKey)
            else:
                value = targetCDB.get(searchKey)
            return value
