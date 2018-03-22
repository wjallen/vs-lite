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
cp ${MASTERDIR}/${SYSTEM}.receptor.pdb ./
perl -pi -e 's/\r\n/\n/g' ${SYSTEM}.receptor.pdb


### Read protein in with leap to renumber residues from 1
##################################################
cat << EOF > leap1.in
set default PBradii mbondi2
source leaprc.protein.ff14SB
loadoff ions94.lib
REC = loadpdb ${SYSTEM}.receptor.pdb
saveamberparm REC ${SYSTEM}.receptor.parm ${SYSTEM}.receptor.crd
charge REC
quit
EOF
##################################################

${AMBERDIR}/tleap -s -f leap1.in >& leap1.log
${AMBERDIR}/ambpdb -p ${SYSTEM}.receptor.parm -tit "${SYSTEM}_processed" <${SYSTEM}.receptor.crd > ${SYSTEM}.receptor.processed.pdb


### Prepare the ligand file with antechamber
${AMBERDIR}/antechamber -i ../001.lig-prep/${SYSTEM}.lig.am1bcc.mol2 -fi mol2  -o ${SYSTEM}.lig.ante.prep -fo prepi
${AMBERDIR}/antechamber -i ../001.lig-prep/${SYSTEM}.lig.am1bcc.mol2 -fi mol2  -o ${SYSTEM}.lig.ante.pdb -fo pdb
${AMBERDIR}/parmchk -i ${SYSTEM}.lig.ante.prep -f prepi -o ${SYSTEM}.lig.ante.frcmod


exit
















### Make tleap input for Complex
##################################################
cat << EOF > leap2.in
set default PBradii mbondi2
source leaprc.protein.ff14SB
source leaprc.gaff
loadoff ions94.lib
PRO = loadpdb pro.noH.pdb
EOF

cat ssbonds.txt >> leap2.in

cat << EOF >> leap2.in
loadamberparams ${SYSTEM}.lig.ante.frcmod
loadamberprep ${SYSTEM}.lig.ante.prep
LIG = loadpdb ${SYSTEM}.lig.ante.pdb
REC = combine { PRO }
COM = combine { REC LIG }
saveamberparm LIG ${SYSTEM}.lig.parm ${SYSTEM}.lig.ori.crd
saveamberparm PRO ${SYSTEM}.pro.parm ${SYSTEM}.pro.ori.crd
saveamberparm REC ${SYSTEM}.rec.parm ${SYSTEM}.rec.ori.crd
saveamberparm COM ${SYSTEM}.com.parm ${SYSTEM}.com.ori.crd
quit
EOF
##################################################



### Use leap to generate complex
echo "------------ LEAP RUN_002 SUMMARY -------------"
echo "Purpose: Generate complex with ssbonds"
${AMBERDIR}/tleap -s -f com.leap.in >& ${SYSTEM}.com.leap.log
${AMBERDIR}/ambpdb -p ${SYSTEM}.lig.parm -tit "lig" <${SYSTEM}.lig.ori.crd > ${SYSTEM}.lig.ori.pdb
${AMBERDIR}/ambpdb -p ${SYSTEM}.pro.parm -tit "pro" <${SYSTEM}.pro.ori.crd > ${SYSTEM}.pro.ori.pdb
${AMBERDIR}/ambpdb -p ${SYSTEM}.rec.parm -tit "rec" <${SYSTEM}.rec.ori.crd > ${SYSTEM}.rec.ori.pdb
${AMBERDIR}/ambpdb -p ${SYSTEM}.com.parm -tit "com" <${SYSTEM}.com.ori.crd > ${SYSTEM}.com.ori.pdb
echo -n "atoms in ${SYSTEM}.lig.ori.pdb = "
grep -c ATOM ${SYSTEM}.lig.ori.pdb
echo -n "atoms in ${SYSTEM}.pro.ori.pdb = "
grep -c ATOM ${SYSTEM}.pro.ori.pdb
echo -n "atoms in ${SYSTEM}.rec.ori.pdb = "
grep -c ATOM ${SYSTEM}.rec.ori.pdb
echo -n "atoms in ${SYSTEM}.com.ori.pdb = "
grep -c ATOM ${SYSTEM}.com.ori.pdb


### Run sander to minimize hydrogen positions
echo "Creating ori.mol2 files before minimization"
${AMBERDIR}/ambpdb -p ${SYSTEM}.lig.parm < ${SYSTEM}.lig.ori.crd -mol2 > ${SYSTEM}.lig.ori.mol2 
${AMBERDIR}/ambpdb -p ${SYSTEM}.pro.parm < ${SYSTEM}.pro.ori.crd -mol2 > ${SYSTEM}.pro.ori.mol2 
${AMBERDIR}/ambpdb -p ${SYSTEM}.rec.parm < ${SYSTEM}.rec.ori.crd -mol2 > ${SYSTEM}.rec.ori.mol2 
${AMBERDIR}/ambpdb -p ${SYSTEM}.com.parm < ${SYSTEM}.com.ori.crd -mol2 > ${SYSTEM}.com.ori.mol2 

##################################################
cat <<EOF >sander.in
01mi minimization
 &cntrl
    imin = 1, maxcyc = 100,
    ntpr = 10, ntx=1,
    ntb = 0, cut = 10.0,
    ntr = 1, drms=0.1,
    restraintmask = "!@H=",
    restraint_wt  = 1000.0
&end
EOF
##################################################

echo "---------------------------------------------------------"
echo "Minimizing complex with sander"
${AMBERDIR}/sander -O -i sander.in -o sander.out -p ${SYSTEM}.com.parm -c ${SYSTEM}.com.ori.crd -ref ${SYSTEM}.com.ori.crd -r ${SYSTEM}.com.min.rst
${AMBERDIR}/ambpdb -p ${SYSTEM}.com.parm -tit "${SYSTEM}.com.min" <${SYSTEM}.com.min.rst> ${SYSTEM}.com.min.pdb
grep "SANDER BOMB" sander.out  
grep -A1 NSTEP sander.out | tail -2

if (! -s ${SYSTEM}.com.min.rst) then
	echo "Complex minimizaton failed! Terminating."
	exit
endif


### Run sander on ligand alone to see if gaff screwed up anything
echo "---------------------------------------------------------"

##################################################
cat <<EOF1 >sander.lig.in
01mi minimization
 &cntrl
    imin = 1, maxcyc = 1000,
    ntpr = 10, ntx=1,
    ntb = 0, cut = 10.0,
    ntr = 0, drms=0.1,
&end
EOF1
##################################################

echo "Minimizing unrestrained gas-phase ligand alone with sander"
${AMBERDIR}/sander -O -i sander.lig.in -o sander.lig.out -p ${SYSTEM}.lig.parm -c ${SYSTEM}.lig.ori.crd -r ${SYSTEM}.lig.only.min.rst
${AMBERDIR}/ambpdb -p ${SYSTEM}.lig.parm < ${SYSTEM}.lig.only.min.rst -mol2 > ${SYSTEM}.lig.only.min.mol2
grep "SANDER BOMB" sander.lig.out
grep -A1 NSTEP sander.lig.out | tail -2
echo -n "Minimizing Ligand 1000 steps alone rmsd "
python ${scriptdir}/calc_rmsd_mol2.py ${SYSTEM}.lig.ori.mol2 ${SYSTEM}.lig.only.min.mol2




### Extract some files from the minimized complex
echo "---------------------------------------------------------"
echo "Extracting receptor with ptraj"
echo "trajin ${SYSTEM}.com.min.rst" > rec.ptraj.in
echo "strip :LIG" >> rec.ptraj.in
echo "trajout rec.min.rst restart"  >> rec.ptraj.in
${AMBERDIR}/cpptraj -p ${SYSTEM}.com.parm -i rec.ptraj.in >& rec.ptraj.out
grep STRIP rec.ptraj.out 
echo "Writing receptor mol2"
${AMBERDIR}/ambpdb -p ${SYSTEM}.rec.parm < rec.min.rst -mol2 > ${SYSTEM}.rec.min.mol2
echo "Creating ligand mol2 file"
echo "trajin ${SYSTEM}.com.min.rst" > lig.ptraj.in
echo "strip !(:LIG)" >> lig.ptraj.in
echo "trajout lig.min.rst restart"  >> lig.ptraj.in
${AMBERDIR}/cpptraj ${SYSTEM}.com.parm -i lig.ptraj.in >& lig.ptraj.out
grep STRIP lig.ptraj.out
${AMBERDIR}/ambpdb -p ${SYSTEM}.lig.parm < lig.min.rst -mol2 > ${SYSTEM}.lig.min.mol2 
${AMBERDIR}/ambpdb -p ${SYSTEM}.com.parm < ${SYSTEM}.com.min.rst -mol2 > ${SYSTEM}.com.min.mol2 


### Compute some RMSDs to check for consistency
echo -n "Minimized Ligand rmsd "
python ${scriptdir}/calc_rmsd_mol2.py ${SYSTEM}.lig.ori.mol2 ${SYSTEM}.lig.min.mol2
echo -n "Minimized Receptor rmsd "
python ${scriptdir}/calc_rmsd_mol2.py ${SYSTEM}.rec.ori.mol2 ${SYSTEM}.rec.min.mol2
echo -n "Minimized Complex rmsd "
python ${scriptdir}/calc_rmsd_mol2.py ${SYSTEM}.com.ori.mol2 ${SYSTEM}.com.min.mol2
python ${scriptdir}/clean_mol2.py ${SYSTEM}.rec.min.mol2 ${SYSTEM}.rec.python.mol2 
python ${scriptdir}/clean_mol2.py ${SYSTEM}.lig.min.mol2 ${SYSTEM}.lig.python.mol2


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

${dockdir}/grid -v -i grid.in -o grid.out
echo -n "CHECK GRID: " 
grep "Total charge on" grid.out  


### Remove some extra files
rm -f showbox vdw.defn chem.defn box.pdb
rm -f antechamber tleap teLeap parmchk ambpdb sander
rm -f ANTE* ATOMTYPE.INF NEWPDB.PDB PREP.INF
rm -f ions.frcmod ions.lib parm.e16.dat gaff*frcmod y2p.* heme.*
rm -f ${SYSTEM}.rec.min.mol2 ${SYSTEM}.rec.nomin.mol2 ${SYSTEM}.rec.foramber.pdb 
rm -f ${SYSTEM}.com.* ${SYSTEM}.lig.* ${SYSTEM}.rec.leap* ${SYSTEM}.rec.gas*
rm -f mdinfo grid.in sander.* ssbonds.txt


exit
