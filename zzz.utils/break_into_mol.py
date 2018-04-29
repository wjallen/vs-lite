#!/usr/bin/env python

import sys


def break_into_mol(input_filename):

    input_file = open(input_filename, 'r')
    count = 0

    for line in input_file:

        if (count == 0) and (" Name:" in line):
            count = 1
            last_three = line[-4:-1]
            name = last_three + "/" + line.split()[2] + ".mol2"
            outfile = file(str(name), 'w')
            outfile.write(line)

        else:
            if (count > 0) and (" Name:" not in line):
                outfile.write(line)

            elif (count > 0) and (" Name:" in line):
                outfile.close()
                last_three = line[-4:-1]
                name = last_three + "/" + line.split()[2] + ".mol2"
                outfile = file(str(name), 'w')
                outfile.write(line)

    outfile.close()
    return


def main():

    if (len(sys.argv) != 2):
        print "Usage: " + sys.argv[0] + " <input mol2>"
        return

    input_filename = sys.argv[1]
    break_into_mol(input_filename)
    return


if __name__ == "__main__":
    main()

