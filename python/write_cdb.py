# -*- coding: utf-8 -*-
# usage: python write_cdb.py -d /somewhere/test.cdb -k test.cdb.keymap -i test.txt.gz
# *** test.txt.gz should be sorted *** 

from CDB_Writer import CDB_Writer
import argparse
import gzip
import codecs


def main():
    DEFAULTLFS = 3.2 * 1024 * 1024 * 1024
    parser = argparse.ArgumentParser(description="make and split CDBs")
    parser.add_argument('--inputfile', '-i', type=str,
                        help="key-value format input file")
    parser.add_argument('--dbname', '-d', type=str, help="cdb prefix")
    parser.add_argument('--keymapfile', '-k', type=str, help="keymap of cdbs")
    parser.add_argument('--limit_file_size', '-l', type=int, default=DEFAULTLFS,
                        help="limit file size of each cdbs")
    parser.add_argument('--encoding_in', type=str, default='utf-8',
                        help="default encoding of input")
    parser.add_argument('--encoding_out', '-e', type=str, default='utf-8',
                        help="default encoding of cdb")

    args = parser.parse_args()
    inputfile = args.inputfile
    dbname = args.dbname
    keymapfile = args.keymapfile
    limit_file_size = args.limit_file_size
    encoding_in = args.encoding_in
    encoding_out = args.encoding_out

    maker = CDB_Writer(dbname, keymapfile, limit_file_size, encoding_out)
    reader = codecs.getreader(encoding_in)
    with gzip.open(inputfile) as f:
        f = reader(f)
        for l in iter(f.readline, ''):
            kv = l.strip().split(' ')
            k = kv[0]
            # assumption: value is not separeted by ' '
            v = kv[1]
            maker.add(k, v)
    del maker

if __name__ == "__main__":
    main()
