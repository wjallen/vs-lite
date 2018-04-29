#!/usr/bin/env python

import math, sys
import os.path
import subprocess
from math import sqrt


class molecule_small:
    def __init__(self, name_dock, cont_score):
        self.name_dock   = str(name_dock)
        self.cont_score  = float(cont_score)

    def __cmp__(self, other):
        return cmp(self.cont_score, other.cont_score)
        

# Class for storing molecule information
class molecule:
    def __init__(self, name_dock,
                 cont_score, vdw, es, int_energy, num_hb, rot_bond,
                 fps_vdw, fps_es, fps_hb, 
                 fms, fms_tot, fms_max_ref, fms_max_lig,  
                 fms_nphob, fms_ndon, fms_nacc, fms_naro, fms_npos, fms_nneg, fms_nring,
                 vos, vos_geo, vos_hvy, vos_pos, vos_neg, vos_phob, vos_phil ):
                 
        self.name_dock   = str(name_dock)
        self.cont_score  = float(cont_score)
        self.vdw         = float(vdw)
        self.es          = float(es)
        self.int_energy  = float(int_energy)
        self.num_hb      = int(num_hb)
        self.rot_bond    = int(rot_bond)
        self.fps_sum     = float(fps_vdw + fps_es)
        self.fps_vdw     = float(fps_vdw)
        self.fps_es      = float(fps_es)
        self.fps_hb      = float(fps_hb)
        self.desc_score  = float(cont_score + fps_vdw + fps_es)
        self.fms         = float(fms)
        self.fms_tot     = int(fms_tot)
        self.fms_max_ref = int(fms_max_ref)
        self.fms_max_lig = int(fms_max_lig)
        self.fms_nphob   = int(fms_nphob)
        self.fms_ndon    = int(fms_ndon)
        self.fms_nacc    = int(fms_nacc)
        self.fms_naro    = int(fms_naro)
        self.fms_npos    = int(fms_npos)
        self.fms_nneg    = int(fms_nneg)
        self.fms_nring   = int(fms_nring)
        self.vos         = float(vos)
        self.vos_geo     = float(vos_geo)
        self.vos_hvy     = float(vos_hvy)
        self.vos_pos     = float(vos_pos)
        self.vos_neg     = float(vos_neg)
        self.vos_phob    = float(vos_phob)
        self.vos_phil    = float(vos_phil)

    def __cmp__(self, other):
        return cmp(self.cont_score, other.cont_score)

# Function to write molecule information in csv format
def write_molecule_small(data, file):
    file.write( str(data.name_dock) + "," + str(data.cont_score) + "\n" )



# Function to write molecule information in csv format
def write_molecule(data, file):
    file.write( str(data.name_dock) + "," + str(data.cont_score) + "," + str(data.vdw) + "," +
                str(data.es) + "," + str(data.int_energy) + "," + str(data.num_hb) + "," +
                str(data.rot_bond) + "," + str(data.fps_sum) + "," + str(data.fps_vdw) + "," + str(data.fps_es) + "," + 
                str(data.fps_hb) + "," + str(data.desc_score) + "," + str(data.fms) + "," + str(data.fms_tot) + "," +
                str(data.fms_max_ref) + "," + str(data.fms_max_lig) + "," + str(data.fms_nphob) + "," +
                str(data.fms_ndon) + "," + str(data.fms_nacc) + "," + str(data.fms_naro) + "," +
                str(data.fms_npos) + "," + str(data.fms_nneg) + "," + str(data.fms_nring) + "," +
                str(data.vos) + "," + str(data.vos_geo) + "," + str(data.vos_hvy) + "," +
                str(data.vos_pos) + "," + str(data.vos_neg) + "," + str(data.vos_phob) + "," +
                str(data.vos_phil) + "\n" )



# Read molecules from a multi mol2 file
def read_molecule_small(in_mol2, in_rotbonds, max_num):

    infile = open(in_mol2, 'r')
    long_list = []

    for line in infile:

        linesplit = line.split() 
        if ( len (linesplit) == 3):

            if (linesplit[1] == "Name:"): name_dock = str(linesplit[2])
            elif (linesplit[1] == "Continuous_Score:"):
                cont_score = float(linesplit[2])
                my_data = molecule_small( name_dock, cont_score)
                long_list.append(my_data)
		if (len(long_list) % 1000 == 0):
                    print len(long_list)
            else:
                pass

    infile.close()
    del(infile)
    del(line)

    # sort by the continuous score (vdw+es)
    print "Sorting..."
    long_list.sort()


    # make a short list
    short_list = []
    zinc_names = []
    i = 0
    j = 0

    while (i < max_num):
        if j in range(len(long_list)):
            if not (long_list[j].name_dock in zinc_names):
                zinc_names.append(long_list[j].name_dock)
                short_list.append(long_list[j])
                j += 1
                i += 1
            else:
                j += 1
        else:
            break

    return long_list, short_list;


# Read molecules from a multi mol2 file
def read_molecule(in_mol2, in_rotbonds, max_num):

    infile = open(in_mol2, 'r')
    long_list = []

    for line in infile:

        linesplit = line.split() 
        if ( len (linesplit) == 3):

            if (linesplit[1] == "Name:"):

                name_dock = str(linesplit[2])
                command = "grep -m 1 " + name_dock + " " + in_rotbonds + " | awk -F, '{print $2}'"
                p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
                rot_bond, error = p.communicate()
                rot_bond.strip()

            if (linesplit[1] == "Continuous_Score:"): cont_score = float(linesplit[2])
            if (linesplit[1] == "desc_Continuous_vdw_energy:"): vdw = float(linesplit[2])
            if (linesplit[1] == "desc_Continuous_es_energy:"): es = float(linesplit[2])
            if (linesplit[1] == "desc_FPS_num_hbond:"): num_hb = int(linesplit[2])
            if (linesplit[1] == "desc_FPS_vdw_fps:"): fps_vdw = float(linesplit[2])
            if (linesplit[1] == "desc_FPS_es_fps:"): fps_es = float(linesplit[2])
            if (linesplit[1] == "desc_FPS_hb_fps:"): fps_hb = float(linesplit[2])
            if (linesplit[1] == "Pharmacophore_Score:"): fms = float(linesplit[2])
            if (linesplit[1] == "desc_FMS_num_match_tot:"): fms_tot = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_max_match_ref:"): fms_max_ref = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_max_match_mol:"): fms_max_lig = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_num_hydrophobic_matched:"): fms_nphob = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_num_donor_matched:"): fms_ndon = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_num_acceptor_matched:"): fms_nacc = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_num_aromatic_matched:"): fms_naro = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_num_positive_matched:"): fms_npos = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_num_negative_matched:"): fms_nneg = int(linesplit[2])
            if (linesplit[1] == "desc_FMS_num_ring_matched:"): fms_nring = int(linesplit[2])
            if (linesplit[1] == "Property_Volume_Score:"): vos = float(linesplit[2])
            if (linesplit[1] == "desc_VOS_geometric_vo:"): vos_geo = float(linesplit[2])
            if (linesplit[1] == "desc_VOS_hvy_atom_vo:"): vos_hvy = float(linesplit[2])
            if (linesplit[1] == "desc_VOS_pos_chrg_atm_vo:"): vos_pos = float(linesplit[2])
            if (linesplit[1] == "desc_VOS_neg_chrg_atm_vo:"): vos_neg = float(linesplit[2])
            if (linesplit[1] == "desc_VOS_hydrophobic_atm_vo:"): vos_phob = float(linesplit[2])
            if (linesplit[1] == "desc_VOS_hydrophilic_atm_vo:"): vos_phil = float(linesplit[2])

            if (linesplit[1] == "Internal_energy_repulsive:"):

                int_energy = float(linesplit[2])
                my_data = molecule( name_dock,
                                    cont_score, vdw, es, int_energy, num_hb, rot_bond,
                                    fps_vdw, fps_es, fps_hb, 
                                    fms, fms_tot, fms_max_ref, fms_max_lig,  
                                    fms_nphob, fms_ndon, fms_nacc, fms_naro, fms_npos, fms_nneg, fms_nring,
                                    vos, vos_geo, vos_hvy, vos_pos, vos_neg, vos_phob, vos_phil )
                long_list.append(my_data)
		if (len(long_list) % 1000 == 0):
                    print len(long_list)

    infile.close()
    del(infile)
    del(line)

    # sort by the continuous score (vdw+es)
    #print "Sorting..."
    #long_list.sort()


    ## make a short list
    short_list = []
    #zinc_names = []
    #i = 0
    #j = 0

    #while (i < max_num):
    #    if j in range(len(long_list)):
    #        if not (long_list[j].name_dock in zinc_names):
    #            zinc_names.append(long_list[j].name_dock)
    #            short_list.append(long_list[j])
    #            j += 1
    #            i += 1
    #        else:
    #            j += 1
    #    else:
    #        break

    return long_list, short_list;

# Write a new csv file
def write_csv_small(data, filename):
    filehandle = open(filename, 'w')
    filehandle.write( "name_dock,cont_score\n" )
    for i in range(len(data)):
        write_molecule_small(data[i], filehandle)
    filehandle.close()
    return;



# Write a new csv file
def write_csv(data, filename):
    filehandle = open(filename, 'w')
    filehandle.write( "name_dock,cont_score,vdw,es,int_energy,num_hb,rot_bond,fps_sum,fps_vdw,fps_es,fps_hb,desc_score,fms,fms_tot,fms_max_ref,fms_max_lig,fms_nphob,fms_ndon,fms_nacc,fms_naro,fms_npos,fms_nneg,fms_nring,vos,vos_geo,vos_hvy,vos_pos,vos_neg,vos_phob,vos_phil\n" )
    for i in range(len(data)):
        write_molecule(data[i], filehandle)
    filehandle.close()
    return;


# Main
def main():

    if (len(sys.argv) != 6):
        print "Usage: " + sys.argv[0] + " <small,full> <in_mol2> <in_rotbonds> <max_num> <out_prefix>"
	return

    run_type      = sys.argv[1]
    in_mol2       = sys.argv[2]
    in_rotbonds   = sys.argv[3]
    max_num       = int(sys.argv[4])
    out_prefix    = sys.argv[5]

    if (run_type == "small"):
        long_list, short_list   = read_molecule_small(in_mol2, in_rotbonds, max_num);
        out_filename_long_list  = out_prefix + "_sorted_contScore_all_small.csv";
        out_filename_short_list = out_prefix + "_sorted_contScore_" + str(max_num) + "_small.csv";
    
        write_csv_small(long_list, out_filename_long_list)
        write_csv_small(short_list, out_filename_short_list)
        return

    elif (run_type == "full"):
        long_list, short_list   = read_molecule(in_mol2, in_rotbonds, max_num);
        out_filename_long_list  = out_prefix + "_sorted_contScore_all.csv";
        #out_filename_short_list = out_prefix + "_sorted_contScore_" + str(max_num) + ".csv";
    
        write_csv(long_list, out_filename_long_list)
        #write_csv(short_list, out_filename_short_list)
        return

    else:
        return


if __name__ == "__main__":
    main()


