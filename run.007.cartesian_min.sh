#!/bin/bash
#
# After docking all of the ligands from the library to the grid, minimize and
# rescore each of them in Cartesian space.
#

### Set some paths
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/run.vars.sh"


### Check to see if at least one chunk of molecules exists
if [ ! -e ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}/chunk0/${VENDOR}.0.output_scored.mol2 ]; then
	echo "You have to dock the chunks first. Exiting."
	exit
fi


### Make the appropriate directory
if [ ! -e ${ROOTDIR}/${SYSTEM}/007.cartesian-min ]; then
	mkdir -p ${ROOTDIR}/${SYSTEM}/007.cartesian-min
fi

rm -fr ${ROOTDIR}/${SYSTEM}/007.cartesian-min/${VENDOR}
mkdir -p ${ROOTDIR}/${SYSTEM}/007.cartesian-min/${VENDOR}
cd ${ROOTDIR}/${SYSTEM}/007.cartesian-min/${VENDOR}


### Count the number of chunks
export NUM_CHUNKS=` ls ${ZINCDIR}/${VENDOR} | grep -c chunk `
echo "number of chunks = ${NUM_CHUNKS}"
export CHUNK="0"


### Iterate over each chunk, concatenate them together
while [ ${CHUNK} -lt ${NUM_CHUNKS} ]; do

	if [ -e ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}/chunk${CHUNK}/${VENDOR}.${CHUNK}.output_scored.mol2 ]; then
		cat  ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}/chunk${CHUNK}/${VENDOR}.${CHUNK}.output_scored.mol2 >> input.mol2
	else
		echo "Could not find an output mol2 file in ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}/${CHUNK}"
	fi

	((CHUNK++))
done

### Cat on the leftover chunk, if it exists
if [ -e ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}/leftover/${VENDOR}.leftover.output_scored.mol2 ]; then
	cat  ${ROOTDIR}/${SYSTEM}/006.dock-SGE/${VENDOR}/leftover/${VENDOR}.leftover.output_scored.mol2 >> input.mol2
fi


### Write the dock.in file
##################################################
cat <<EOF >${SYSTEM}.${VENDOR}.cartesian_min.in
conformer_search_type                                        rigid
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
internal_energy_cutoff                                       100.0
ligand_atom_file                                             input.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          no
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              yes
contact_score_primary                                        no
contact_score_secondary                                      no
grid_score_primary                                           no
grid_score_secondary                                         no
multigrid_score_primary                                      no
multigrid_score_secondary                                    no
dock3.5_score_primary                                        no
dock3.5_score_secondary                                      no
continuous_score_primary                                     yes
continuous_score_secondary                                   no
cont_score_rec_filename                                      ${ROOTDIR}/${SYSTEM}/002.rec-prep/${SYSTEM}.rec.clean.mol2
cont_score_att_exp                                           ${ATTRACTIVE}
cont_score_rep_exp                                           ${REPULSIVE}
cont_score_rep_rad_scale                                     1
cont_score_use_dist_dep_dielectric                           yes
cont_score_dielectric                                        4.0
cont_score_vdw_scale                                         1
cont_score_es_scale                                          1
footprint_similarity_score_secondary                         no
pharmacophore_score_secondary                                no
descriptor_score_secondary                                   no
gbsa_zou_score_secondary                                     no
gbsa_hawkins_score_secondary                                 no
SASA_score_secondary                                         no
amber_score_secondary                                        no
minimize_ligand                                              yes
simplex_max_iterations                                       1000
simplex_tors_premin_iterations                               0
simplex_max_cycles                                           1
simplex_score_converge                                       0.1
simplex_cycle_converge                                       1.0
simplex_trans_step                                           1.0
simplex_rot_step                                             0.1
simplex_tors_step                                            10.0
simplex_random_seed                                          0
simplex_restraint_min                                        no
atom_model                                                   all
vdw_defn_file                                                ${DOCKPARAMS}/vdw_AMBER_parm99.defn
flex_defn_file                                               ${DOCKPARAMS}/flex.defn
flex_drive_file                                              ${DOCKPARAMS}/flex_drive.tbl
ligand_outfile_prefix                                        ${VENDOR}.output
write_orientations                                           no
num_scored_conformers                                        1
rank_ligands                                                 no
EOF
##################################################


### Write the job batch file
##################################################
cat <<EOF >${SYSTEM}.${VENDOR}.cartesian_min.slurm
#!/bin/bash
#SBATCH -J ${SYSTEM}.${VENDOR}           # Job name
#SBATCH -o ${SYSTEM}.${VENDOR}.o%j       # Name of stdout output file
#SBATCH -e ${SYSTEM}.${VENDOR}.e%j       # Name of stderr error file
#SBATCH -p skx-normal             # Queue (partition) name
#SBATCH -N 4                      # Total # of nodes 
#SBATCH -n 192                    # Total # of mpi tasks
#SBATCH -t 24:00:00               # Run time (hh:mm:ss)
#SBATCH -A Sepin-identification   # Allocation name (req'd if you have more than 1)

# Launch MPI code... 

cd ${ROOTDIR}/${SYSTEM}/007.cartesian-min/${VENDOR}/
ibrun ${DOCKDIR}/dock6.mpi -v -i ${SYSTEM}.${VENDOR}.cartesian_min.in \
                              -o ${SYSTEM}.${VENDOR}.cartesian_min.out

EOF
##################################################


### Submit the job
echo "Submitting ${SYSTEM}.${VENDOR}.cartesian_min "
sbatch ${SYSTEM}.${VENDOR}.cartesian_min.slurm


exit

