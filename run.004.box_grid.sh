#!/bin/bash
#
# This script will generate a box and grid for docking. Variables are set in
# the run.vars.sh script. 6-9 VDW exponents and grid space 0.4 is typical for
# DOCK 6.
#

### Set some paths
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/run.vars.sh"


### Check to see if the spheres were prepared correctly
if [ ! -e ${ROOTDIR}/${SYSTEM}/003.dms-sph/${SYSTEM}.rec.close.sph ]; then
	echo "You have to prepare the spheres first. Exiting."
	exit
fi


### Make the sphere directory
rm -fr ${ROOTDIR}/${SYSTEM}/004.box-grid
mkdir -p ${ROOTDIR}/${SYSTEM}/004.box-grid
cd ${ROOTDIR}/${SYSTEM}/004.box-grid


### Link and copy some files here
cp ${ROOTDIR}/${SYSTEM}/002.rec-prep/${SYSTEM}.rec.clean.mol2 ./
cp ${ROOTDIR}/${SYSTEM}/003.dms-sph/${SYSTEM}.rec.close.sph ./
cp ${DOCKPARAMS}/vdw_AMBER_parm99.defn ./vdw.defn
cp ${DOCKPARAMS}/chem.defn ./chem.defn


### Construct box.pdb centered on spheres 
##################################################
cat <<EOF >box.in
yes
${BOX_MARGIN}
${SYSTEM}.rec.close.sph
1
${SYSTEM}.box.pdb
EOF
##################################################
${DOCKDIR}/showbox < box.in


### Construct grid using receptor mol2 file
##################################################
cat <<EOF >grid.in
compute_grids                  yes
grid_spacing                   ${GRID_SPACING}
output_molecule                no
contact_score                  no
chemical_score		       no
energy_score                   yes
energy_cutoff_distance         999
atom_model                     a
attractive_exponent            ${ATTRACTIVE}
repulsive_exponent             ${REPULSIVE}
distance_dielectric            yes
dielectric_factor              4
bump_filter                    yes
bump_overlap                   0.75
receptor_file                  ${SYSTEM}.rec.clean.mol2
box_file                       ${SYSTEM}.box.pdb
vdw_definition_file            vdw.defn
chemical_definition_file       chem.defn
score_grid_prefix              ${SYSTEM}.rec
EOF
##################################################
${DOCKDIR}/grid -v -i grid.in -o grid.out


exit

