#!/bin/bash
#
# This script runs dms and sphgen on the prepared receptor.
#

### Set some paths
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/run.vars.sh"


### Check to see if the protein file was prepared correctly
if [ ! -e ${ROOTDIR}/${SYSTEM}/002.rec-prep/${SYSTEM}.rec.clean.mol2 ]; then
	echo "You have to prepare the protein first. Exiting."
	exit
fi


### Check to see if the noH protein exists
if [ ! -e ${MASTERDIR}/${SYSTEM}.noH.pdb ]; then
	echo "Ligand file does not seem to exist. Exiting."
	exit
fi


### Make the sphere directory
rm -fr ${ROOTDIR}/${SYSTEM}/003.dms-sph
mkdir -p ${ROOTDIR}/${SYSTEM}/003.dms-sph
cd ${ROOTDIR}/${SYSTEM}/003.dms-sph


### Run the program DMS 
cp ${UTILSDIR}/dms ./
cp ${UTILSDIR}/radii ./
cp ${MASTERDIR}/${SYSTEM}.noH.pdb ./

#./dms ${SYSTEM}.noH.pdb -a -g ${SYSTEM}.rec.dms.log -n -o ${SYSTEM}.rec.dms.out
$WORK/lonestar/apps/dms/bin/dms ${SYSTEM}.noH.pdb -a -g ${SYSTEM}.rec.dms.log -n -o ${SYSTEM}.rec.dms.out


### Write an input file and generate sphere clusters on the molecular surface with sphgen
##################################################
cat <<EOF >INSPH
${SYSTEM}.rec.dms.out
R
X
0.0
4.0
1.4
${SYSTEM}.rec.sph
EOF
##################################################

cp ${UTILSDIR}/sphgen_cpp ./
./sphgen_cpp


### Convert the clusters (pruned shperes, not cluster 0) to a PDB file for viewing
##################################################
cat <<EOF >showsphere1.in
${SYSTEM}.rec.sph
-1
N
clusters
N
EOF
##################################################

${DOCKDIR}/showsphere < showsphere1.in
cat clusters*pdb >> ${SYSTEM}.rec.sph.pdb


### Make a PDB and a SPH file that contains only spheres close to the ligand
cp ${ROOTDIR}/${SYSTEM}/001.lig-prep/${SYSTEM}.lig.am1bcc.mol2 ./
${DOCKDIR}/sphere_selector ${SYSTEM}.rec.sph ${SYSTEM}.lig.am1bcc.mol2 ${SPHCUT}

##################################################
cat <<EOF >showsphere2.in
selected_spheres.sph
-1
N
selected_spheres
N
EOF
##################################################

${DOCKDIR}/showsphere < showsphere2.in
mv selected_spheres.sph ${SYSTEM}.rec.close.sph
mv selected_spheres_1.pdb ${SYSTEM}.rec.close.sph.pdb


### Remove some files
rm -f clusters*pdb
rm -f dms radii sphgen_cpp


exit

