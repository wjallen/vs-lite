#!/usr/bin/env python

import math, sys
import os.path


class Mol:
    def __init__(self,name,atom_list,bond_list,residue_list):
        self.name       = str(name)
        self.atom_list  = atom_list
        self.bond_list  = bond_list
	self.residue_list = residue_list

class atom:
    def __init__(self,X,Y,Z,Q,type,name,num,resnum,resname):
        self.X = float(X)
        self.Y = float(Y)
        self.Z = float(Z)
        self.Q = float(Q)
        self.heavy_atom = False
        self.type = type
        self.name = name
        self.num  = int(num)
	self.resnum  = int(resnum)
	self.resname = resname

class bond:
     def __init__(self,a1_num,a2_num,num,type):
        self.a1_num = int(a1_num)
        self.a2_num = int(a2_num)
        self.num = int(num)
        self.type = type

class residue:
     def __init__(self,atom_list,resnum,resname):
	self.atom_list = atom_list
	self.resnum  = int(resnum)
        self.resname = resname


def read_Mol2_file(file):
    file1 = open(file,'r')
    lines  =  file1.readlines()
    file1.close()

    atom_list = []
    bond_list = []
    residue_list = {}
    mol_list = []

    flag_atom    = False
    flag_bond    = False
    flag_substr  = False
    flag_mol     = False
    flag_getName = False

    i = 0  # i is the num of molecules read so far
    for line in lines:
         linesplit = line.split() #split on white space
         if (len(linesplit) == 1):
            if(linesplit[0] == "@<TRIPOS>MOLECULE"):
               i = i + 1
               #print "READING IN MOL #" + str(i)
               #print "read in molecule info:"
               line_num = 0
               flag_mol = True
               flag_atom = False
               flag_bond = False
               flag_substr = False

            if(linesplit[0] == "@<TRIPOS>ATOM"):
               #print "read in atom info:"
               flag_atom = True
               flag_bond = False
               flag_substr = False
               flag_mol = False

            if(linesplit[0] == "@<TRIPOS>BOND"):
               #print "read in bond info:"
               flag_bond = True
               flag_substr = False
               flag_mol = False
               flag_atom = False

            if(linesplit[0] == "@<TRIPOS>SUBSTRUCTURE"):
               #print "read in substructure info:"
               flag_substr = True
               flag_mol = False
               flag_atom = False
               flag_bond = False

         if (flag_mol and (not flag_getName) and len(linesplit)==1 ):
             if (line_num == 1):
                line_num = 0
                Name = linesplit[0]
                flag_getName = True
             line_num = line_num + 1

         if ((len(linesplit) >= 9 )and (flag_atom)):
             atom_num  = linesplit[0]
             atom_name = linesplit[1]
             X         = linesplit[2]
             Y         = linesplit[3]
             Z         = linesplit[4]
             atom_type = linesplit[5]
             res_num   = int(linesplit[6])
             res_name  = linesplit[7]
             Q         = linesplit[8]
             temp_atom = atom(X,Y,Z,Q,atom_type,atom_name,atom_num,res_num,res_name)
             atom_list.append(temp_atom)
	     if residue_list.has_key(res_num):
     		 residue_list[res_num].append(temp_atom)
    	     else:
                 residue_list[res_num] = [temp_atom]

         elif (len(linesplit) == 4 and flag_bond):
             bond_num  = linesplit[0]
             a1_num    = linesplit[1]
             a2_num    = linesplit[2]
             bond_type = linesplit[3]
             temp_bond = bond(a1_num,a2_num,bond_num,bond_type)
             bond_list.append(temp_bond)

         elif (flag_substr):
                 ID_heavy_atoms(atom_list)
                 data = Mol(Name,atom_list,bond_list,residue_list)
                 mol_list.append(data)
                 flag_getName = False
                 flag_substr = False
                 atom_list = [];bond_list = []

    return mol_list


def write_mol2(molecule,filename):

        outmol2 = open(filename,'w')
        outmol2.write("@<TRIPOS>MOLECULE\n")      #start the MOLECULE RTI (Record Type Indicator)
        outmol2.write(molecule.name+'\n')         #print MOL2FILE name of the molecule
        outmol2.write(" %d %d %d 0 0\n" % (len(molecule.atom_list),
                len(molecule.bond_list), len(molecule.residue_list.keys())))
        # For now, the number of residues is hard-coded to 1. To be fixed.
        outmol2.write("SMALL\n")                  #mol_type
        outmol2.write("USER_CHARGES\n")           #charge_type

        #outmol2.write("\n@<TRIPOS>ATOM\n")      #start the ATOM RTI (Record Type Indicator)
        outmol2.write("@<TRIPOS>ATOM\n")      #start the ATOM RTI (Record Type Indicator)
        for j in range(0,len(molecule.atom_list)):
                outmol2.write("%-5d %-5s %9.4f %9.4f %9.4f %-5s %4s %-6s %8.4f\n" %
                (j+1, molecule.atom_list[j].name, molecule.atom_list[j].X, molecule.atom_list[j].Y,
                molecule.atom_list[j].Z, molecule.atom_list[j].type, molecule.atom_list[j].resnum,
                molecule.atom_list[j].resname, molecule.atom_list[j].Q))

        outmol2.write("@<TRIPOS>BOND\n")
        for m in range(0,len(molecule.bond_list)):
                outmol2.write("%-7d %5d %-5d %s\n" % (molecule.bond_list[m].num,
                molecule.bond_list[m].a1_num, molecule.bond_list[m].a2_num, molecule.bond_list[m].type))

        outmol2.write("@<TRIPOS>SUBSTRUCTURE\n")
        for resnum in molecule.residue_list.keys():
                outmol2.write("%-7d %8s %5d RESIDUE 1 A %3s 1\n" % (resnum,
                molecule.residue_list[resnum][0].resname, # residue name
                molecule.residue_list[resnum][0].num,   # atom num of first atom in this residue
                molecule.residue_list[resnum][0].resname[0:3] )) # residue
        outmol2.close()
        return


def ID_heavy_atoms(atom_list):
    for i in range(len(atom_list)):
        if (atom_list[i].type[0] != 'H'):
            atom_list[i].heavy_atom = True
    return atom_list


def main():
	inmol2 = sys.argv[1]
	outmol2 = sys.argv[2]
	in_molecule = read_Mol2_file(inmol2)[0]
	write_mol2(in_molecule,outmol2)
        return

main()
