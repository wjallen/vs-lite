#!/bin/bash
#
# This script will dock compounds to the grid using single grid energy score.
# Carefully do the math to determine the necessary wall clock times and node 
# DOCK 6.
#

### Set some paths
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/run.vars.sh"


### Check to see if at least one chunk of molecules exists
if [ $( ls ${ZINCDIR}/${VENDOR} | grep -c chunk ) -lt 1 ]; then
	echo "You have to prepare the chunks first. Exiting."
	exit
fi


### Make the sphere directory
if [ ! -e ${ROOTDIR}/${SYSTEM}/006.dock-SGE ]; then
	mkdir -p ${ROOTDIR}/${SYSTEM}/006.dock-SGE
fi

rm -fr ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}
mkdir -p ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}
cd ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}


### Count the number of chunks
export NUM_CHUNKS=` ls ${ZINCDIR}/${VENDOR} | grep -c chunk `
echo "number of chunks = ${NUM_CHUNKS}"
export CHUNK="0"
#export NUM_CHUNKS="5"     # manual override


### Iterate over each chunk
while [ ${CHUNK} -lt ${NUM_CHUNKS} ]; do

	mkdir chunk${CHUNK}/
	cd chunk${CHUNK}/


### Write the dock.in file
##################################################
cat <<EOF >${SYSTEM}.${VENDOR}.${CHUNK}.dock_SGE.in
conformer_search_type                                        flex
user_specified_anchor                                        no
limit_max_anchors                                            no
min_anchor_size                                              5
pruning_use_clustering                                       yes
pruning_max_orients                                          1000
pruning_clustering_cutoff                                    100
pruning_conformer_score_cutoff                               100.0
pruning_conformer_score_scaling_factor                       1.0
use_clash_overlap                                            no
write_growth_tree                                            no
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
internal_energy_cutoff                                       100.0
ligand_atom_file                                             ${ZINCDIR}/${VENDOR}/chunk${CHUNK}_scored.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          no
orient_ligand                                                yes
automated_matching                                           yes
receptor_site_file                                           ${ROOTDIR}/${SYSTEM}/003.dms-sph/${SYSTEM}.rec.close.sph
max_orientations                                             1000
critical_points                                              no
chemical_matching                                            no
use_ligand_spheres                                           no
bump_filter                                                  no
score_molecules                                              yes
contact_score_primary                                        no
contact_score_secondary                                      no
grid_score_primary                                           yes
grid_score_secondary                                         no
grid_score_rep_rad_scale                                     1
grid_score_vdw_scale                                         1
grid_score_es_scale                                          1
grid_score_grid_prefix                                       ${ROOTDIR}/${SYSTEM}/004.box-grid/${SYSTEM}.grid
multigrid_score_secondary                                    no
dock3.5_score_secondary                                      no
continuous_score_secondary                                   no
footprint_similarity_score_secondary                         no
pharmacophore_score_secondary                                no
descriptor_score_secondary                                   no
gbsa_zou_score_secondary                                     no
gbsa_hawkins_score_secondary                                 no
SASA_score_secondary                                         no
amber_score_secondary                                        no
minimize_ligand                                              yes
minimize_anchor                                              yes
minimize_flexible_growth                                     yes
use_advanced_simplex_parameters                              no
simplex_max_cycles                                           1
simplex_score_converge                                       0.1
simplex_cycle_converge                                       1.0
simplex_trans_step                                           1.0
simplex_rot_step                                             0.1
simplex_tors_step                                            10.0
simplex_anchor_max_iterations                                500
simplex_grow_max_iterations                                  500
simplex_grow_tors_premin_iterations                          0
simplex_random_seed                                          0
simplex_restraint_min                                        no
atom_model                                                   all
vdw_defn_file                                                ${TACC_DOCK_PARAM}/vdw_AMBER_parm99.defn
flex_defn_file                                               ${TACC_DOCK_PARAM}/flex.defn
flex_drive_file                                              ${TACC_DOCK_PARAM}/flex_drive.tbl
ligand_outfile_prefix                                        ${VENDOR}.${CHUNK}.output
write_orientations                                           no
num_scored_conformers                                        1
rank_ligands                                                 no
EOF
##################################################


### Write the job batch file
##################################################
cat <<EOF >${SYSTEM}.${VENDOR}.${CHUNK}.dock_SGE.slurm
#!/bin/bash
#SBATCH -J ${SYSTEM}.${VENDOR}.${CHUNK}           # Job name
#SBATCH -o ${SYSTEM}.${VENDOR}.${CHUNK}.o%j       # Name of stdout output file
#SBATCH -e ${SYSTEM}.${VENDOR}.${CHUNK}.e%j       # Name of stderr error file
#SBATCH -p skx-normal             # Queue (partition) name
#SBATCH -N 4                      # Total # of nodes 
#SBATCH -n 192                    # Total # of mpi tasks
#SBATCH -t 36:00:00               # Run time (hh:mm:ss)
#SBATCH -A Sepin-identification   # Allocation name (req'd if you have more than 1)

# Launch MPI code... 

ibrun ./mycode.exe         # Use ibrun instead of mpirun or mpiexec

cd ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}/chunk${chunk}/
ibrun ${DOCKDIR}/dock6.mpi -v -i ${SYSTEM}.${VENDOR}.${CHUNK}.dock_SGE.in \
                              -o ${SYSTEM}.${VENDOR}.${CHUNK}.dock_SGE.out

EOF
##################################################


	### Submit the job
	echo "Submitting chunk named chunk${CHUNK}_scored.mol2"
	sbatch ${SYSTEM}.${VENDOR}.${CHUNK}.dock_SGE.slurm
	((CHUNK++))
	cd ../

done


exit
