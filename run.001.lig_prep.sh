#!/bin/bash
#
# This script prepares the ligand that will be used as a footprint reference.
# Input required is:
#
#     ${SYSTEM}.lig.chimera.mol2
#
# which is the ligand prepared in chimera by adding hydrogens and computing
# gasteiger charges.
#

### Set some paths
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/run.vars.sh"


### Check to see if the ligfile exists
if [ ! -e ${MASTERDIR}/${SYSTEM}.ligand.mol2 ]; then
	echo "Ligand file does not seem to exist. Exiting.";
	exit
fi


### Make the lig-prep directory
rm -fr ${ROOTDIR}/${SYSTEM}/001.lig-prep/
mkdir -p ${ROOTDIR}/${SYSTEM}/001.lig-prep/
cd ${ROOTDIR}/${SYSTEM}/001.lig-prep/

##################################################
cat <<EOF >dock.lig.in
conformer_search_type                rigid
use_internal_energy                  no
ligand_atom_file                     temp.mol2
limit_max_ligands                    no
skip_molecule                        no
read_mol_solvation                   no
calculate_rmsd                       no
use_database_filter                  no
orient_ligand                        no
bump_filter                          no
score_molecules                      no
ligand_outfile_prefix                lig
write_orientations                   no
num_scored_conformers                1
rank_ligands                         no
EOF
##################################################


### Pre-process the ligand with DOCK
perl -pe 's/\r\n/\n/g' ${MASTERDIR}/${SYSTEM}.ligand.mol2 > temp.mol2
${DOCKDIR}/dock6 -i dock.lig.in -o dock.lig.out
mv lig_scored.mol2 ${SYSTEM}.lig.processed.mol2


### Compute ligand charges with antechamber
${AMBERDIR}/acdoctor -i ${SYSTEM}.lig.processed.mol2 -f mol2

${AMBERDIR}/antechamber -fi mol2 -fo mol2 -c bcc -j 5 -at sybyl -s 2 -pf y \
                        -i ${SYSTEM}.lig.processed.mol2 -o ${SYSTEM}.lig.am1bcc.mol2

if [ `grep "No convergence in SCF" sqm.out | wc -l` ]; then
${AMBERDIR}/antechamber -fi mol2 -fo mol2 -c bcc -j 5 -at sybyl -s 2 -pf y \
                        -ek "itrmax=100000, qm_theory='AM1', grms_tol=0.0002, tight_p_conv=0, scfconv=1.d-8" \
                        -i ${SYSTEM}.lig.processed.mol2 -o ${SYSTEM}.lig.am1bcc.mol2
fi

if [ `grep "No convergence in SCF" sqm.out | wc -l` ]; then
${AMBERDIR}/antechamber -fi mol2 -fo mol2 -c gas -j 5 -at sybyl -s 2 -pf y \
                        -i ${SYSTEM}.lig.processed.mol2 -o ${SYSTEM}.lig.gasteiger.mol2
ln -s ${SYSTEM}.lig.gasteiger.mol2 ${SYSTEM}.lig.am1bcc.mol2
fi


### Clean up
mv sqm.out sqm.lig.out
mv sqm.in sqm.lig.in
rm temp.mol2

