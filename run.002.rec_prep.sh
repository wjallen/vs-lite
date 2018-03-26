#!/bin/bash
#
# This script prepares the receptor. Input required is:
#
#     ${SYSTEM}.receptor.pdb
#
# which is the protein prepared in chimera and saved as PDB.
#

### Set some paths
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/run.vars.sh"


### Check to see if the ligand file exists
if [ ! -e ${ROOTDIR}/${SYSTEM}/001.lig-prep/${SYSTEM}.lig.am1bcc.mol2 ]; then
	echo "You have to prepare the ligand first. Exiting."
	exit
fi


### Check to see if the protein file is present, and prepare it for amber
if [ ! -e ${MASTERDIR}/${SYSTEM}.receptor.pdb ]; then
	echo "Receptor file does not seem to exist. Exiting."
	exit
fi


### Make the rec-prep directory
rm -fr ${ROOTDIR}/${SYSTEM}/002.rec-prep/
mkdir -p ${ROOTDIR}/${SYSTEM}/002.rec-prep/
cd ${ROOTDIR}/${SYSTEM}/002.rec-prep/


### Remove unusual newlines from receptor
cp ${MASTERDIR}/${SYSTEM}.receptor.pdb ./${SYSTEM}.rec.pdb
perl -pi -e 's/\r\n/\n/g' ${SYSTEM}.rec.pdb


### Read protein in with leap to renumber residues from 1
##################################################
cat << EOF > leap1.in
set default PBradii mbondi2
source leaprc.protein.ff14SB
loadoff ions94.lib
REC = loadpdb ${SYSTEM}.rec.pdb
saveamberparm REC ${SYSTEM}.rec.parm ${SYSTEM}.rec.crd
charge REC
quit
EOF
##################################################

${AMBERDIR}/tleap -s -f leap1.in >& leap1.log
${AMBERDIR}/ambpdb -p ${SYSTEM}.rec.parm -tit "${SYSTEM}_processed" <${SYSTEM}.rec.crd > ${SYSTEM}.rec.processed.pdb


### Prepare the ligand file with antechamber
${AMBERDIR}/antechamber -i ../001.lig-prep/${SYSTEM}.lig.am1bcc.mol2 -fi mol2  -o ${SYSTEM}.lig.ante.prep -fo prepi
${AMBERDIR}/antechamber -i ../001.lig-prep/${SYSTEM}.lig.am1bcc.mol2 -fi mol2  -o ${SYSTEM}.lig.ante.pdb -fo pdb
${AMBERDIR}/parmchk -i ${SYSTEM}.lig.ante.prep -f prepi -o ${SYSTEM}.lig.ante.frcmod


### Use leap to generate complex
##################################################
cat << EOF > leap2.in
set default PBradii mbondi2
source leaprc.protein.ff14SB
source leaprc.gaff
loadoff ions94.lib
REC = loadpdb ${SYSTEM}.rec.processed.pdb
loadamberparams ${SYSTEM}.lig.ante.frcmod
loadamberprep ${SYSTEM}.lig.ante.prep
LIG = loadpdb ${SYSTEM}.lig.ante.pdb
COM = combine { REC LIG }
saveamberparm LIG ${SYSTEM}.lig.parm ${SYSTEM}.lig.crd
saveamberparm REC ${SYSTEM}.rec.parm ${SYSTEM}.rec.crd
saveamberparm COM ${SYSTEM}.com.parm ${SYSTEM}.com.crd
quit
EOF
##################################################

${AMBERDIR}/tleap -s -f leap2.in >& leap2.log


### Run sander to minimize hydrogen positions
##################################################
cat <<EOF >sander.in
01mi minimization
 &cntrl
    imin = 1, maxcyc = 100,
    ntpr = 10, ntx=1,
    ntb = 0, cut = 10.0,
    ntr = 1, drms=0.1,
    restraintmask = "!@H=",
    restraint_wt = 1000.0
&end
EOF
##################################################

${AMBERDIR}/sander -O -i sander.in -o sander.out -p ${SYSTEM}.com.parm -c ${SYSTEM}.com.crd -ref ${SYSTEM}.com.crd -r ${SYSTEM}.com.min.rst


### Extract some files from the minimized complex
##################################################
cat <<EOF >ptraj1.in
trajin ${SYSTEM}.com.min.rst
strip :LIG
trajout ${SYSTEM}.rec.min.rst restart
EOF
##################################################

${AMBERDIR}/cpptraj -p ${SYSTEM}.com.parm -i ptraj1.in >& ptraj1.out
${AMBERDIR}/ambpdb -p ${SYSTEM}.rec.parm < ${SYSTEM}.rec.min.rst -mol2 > ${SYSTEM}.rec.min.mol2


##################################################
cat <<EOF >ptraj2.in
trajin ${SYSTEM}.com.min.rst
strip !(:LIG) 
trajout ${SYSTEM}.lig.min.rst restart
EOF
##################################################

${AMBERDIR}/cpptraj ${SYSTEM}.com.parm -i ptraj2.in >& ptraj2.out
${AMBERDIR}/ambpdb -p ${SYSTEM}.lig.parm < ${SYSTEM}.lig.min.rst -mol2 > ${SYSTEM}.lig.min.mol2 
${AMBERDIR}/ambpdb -p ${SYSTEM}.com.parm -c ${SYSTEM}.com.min.rst -mol2 > ${SYSTEM}.com.min.mol2 


### Change amber to sybyl atom types in receptor
cp ${UTILSDIR}/ATOMTYPE_CHECK.TAB ./
cp ${UTILSDIR}/fix_margins.py ./

awk 'NR==FNR{a[$1]=$2} NR>FNR{$6=a[$6];print}' ATOMTYPE_CHECK.TAB ${SYSTEM}.rec.min.mol2 > ${SYSTEM}.rec.awk.mol2
python fix_margins.py ${SYSTEM}.rec.awk.mol2 ${SYSTEM}.rec.python.mol2


### Run check grid
##################################################
cat <<EOF >grid.in
compute_grids                  no
output_molecule                yes
box_file                       box.pdb
receptor_file                  ${SYSTEM}.rec.python.mol2
receptor_out_file              ${SYSTEM}.rec.clean.mol2
EOF
##################################################

${DOCKDIR}/grid -v -i grid.in -o grid.out


### Remove some extra files
rm -f ANTECHAMBER* ATOMTYPE.INF NEWPDB.PDB PREP.INF
rm -f *lig.min.pdb *.lig.ante.* *.crd *.parm *.rst
rm -f leap.log mdinfo
rm -f *.rec.python.mol2 *.rec.awk.mol2
rm -f ATOMTYPE_CHECK.TAB fix_margins.py


exit

