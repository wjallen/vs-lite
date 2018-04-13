#!/bin/bash
#
# Once the ligands have been minimized in Cartesian space, rescore each ligand
# with a footprint reference.
#

### Set some paths
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/run.vars.sh"


### Check to see if minimized molecules exist
if [ ! -e ${ROOTDIR}/${SYSTEM}/007.cartesian-min/${VENDOR}/${VENDOR}.output_scored.mol2 ]; then
	echo "You have to minimize the docked molecules first. Exiting."
	exit
fi


### Make the appropriate directory
if [ ! -e ${ROOTDIR}/${SYSTEM}/008.footprint-rescore ]; then
	mkdir -p ${ROOTDIR}/${SYSTEM}/008.footprint-rescore
fi

rm -fr ${ROOTDIR}/${SYSTEM}/008.footprint-rescore/${VENDOR}
mkdir -p ${ROOTDIR}/${SYSTEM}/008.footprint-rescore/${VENDOR}
cd ${ROOTDIR}/${SYSTEM}/008.footprint-rescore/${VENDOR}


### Write the dock.in file to minimize the reference
##################################################
cat <<EOF >${SYSTEM}.${VENDOR}.reference_minimization.in
conformer_search_type                                        rigid
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
internal_energy_cutoff                                       100.0
ligand_atom_file                                             input.mol2
ligand_atom_file                                             ${ROOTDIR}/${SYSTEM}/001.lig-prep/${SYSTEM}.lig.am1bcc.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               yes
use_rmsd_reference_mol                                       yes
rmsd_reference_filename                                      ${ROOTDIR}/${SYSTEM}/001.lig-prep/${SYSTEM}.lig.am1bcc.mol2
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
ligand_outfile_prefix                                        output
write_orientations                                           no
num_scored_conformers                                        1
rank_ligands                                                 no
EOF
##################################################


### Write the dock.in file for footprint rescore
##################################################
cat <<EOF >${SYSTEM}.${VENDOR}.footprint_rescore.in
conformer_search_type                                        rigid
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
internal_energy_cutoff                                       100.0
ligand_atom_file                                             ${ROOTDIR}/${SYSTEM}/007.cartesian-min/${VENDOR}/${VENDOR}.output_scored.mol2
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
continuous_score_primary                                     no
continuous_score_secondary                                   no
footprint_similarity_score_primary                           no
footprint_similarity_score_secondary                         no
pharmacophore_score_primary                                  no
pharmacophore_score_secondary                                no
descriptor_score_primary                                     yes
descriptor_score_secondary                                   no
descriptor_use_grid_score                                    no
descriptor_use_multigrid_score                               no
descriptor_use_continuous_score                              yes
descriptor_use_footprint_similarity                          yes
descriptor_use_pharmacophore_score                           yes
descriptor_use_tanimoto                                      no
descriptor_use_hungarian                                     no
descriptor_use_volume_overlap                                yes
descriptor_cont_score_rec_filename                           ${ROOTDIR}/${SYSTEM}/002.rec-prep/${SYSTEM}.rec.clean.mol2
descriptor_cont_score_att_exp                                ${ATTRACTIVE}
descriptor_cont_score_rep_exp                                ${REPULSIVE}
descriptor_cont_score_rep_rad_scale                          1
descriptor_cont_score_use_dist_dep_dielectric                yes
descriptor_cont_score_dielectric                             4.0
descriptor_cont_score_vdw_scale                              1
descriptor_cont_score_es_scale                               1
descriptor_fps_score_use_footprint_reference_mol2            yes
descriptor_fps_score_footprint_reference_mol2_filename       ${SYSTEM}.lig.min.mol2
descriptor_fps_score_foot_compare_type                       Euclidean
descriptor_fps_score_normalize_foot                          no
descriptor_fps_score_foot_comp_all_residue                   yes
descriptor_fps_score_receptor_filename                       ${ROOTDIR}/${SYSTEM}/002.rec-prep/${SYSTEM}.rec.clean.mol2
descriptor_fps_score_vdw_att_exp                             ${ATTRACTIVE}
descriptor_fps_score_vdw_rep_exp                             ${REPULSIVE}
descriptor_fps_score_vdw_rep_rad_scale                       1
descriptor_fps_score_use_distance_dependent_dielectric       yes
descriptor_fps_score_dielectric                              4.0
descriptor_fps_score_vdw_fp_scale                            1
descriptor_fps_score_es_fp_scale                             10
descriptor_fps_score_hb_fp_scale                             0
descriptor_fms_score_use_ref_mol2                            yes
descriptor_fms_score_ref_mol2_filename                       ${SYSTEM}.lig.min.mol2
descriptor_fms_score_write_reference_pharmacophore_mol2      no
descriptor_fms_score_write_reference_pharmacophore_txt       no
descriptor_fms_score_write_candidate_pharmacophore           no
descriptor_fms_score_write_matched_pharmacophore             no
descriptor_fms_score_compare_type                            overlap
descriptor_fms_score_full_match                              yes
descriptor_fms_score_match_rate_weight                       5.0
descriptor_fms_score_match_dist_cutoff                       1.0
descriptor_fms_score_match_proj_cutoff                       0.7071
descriptor_fms_score_max_score                               20
descriptor_volume_score_reference_mol2_filename              ${SYSTEM}.lig.min.mol2
descriptor_volume_score_overlap_compute_method               analytical
descriptor_weight_cont_score                                 1
descriptor_weight_fps_score                                  0
descriptor_weight_pharmacophore_score                        0
descriptor_weight_volume_overlap_score                       0
gbsa_zou_score_secondary                                     no
gbsa_hawkins_score_secondary                                 no
SASA_score_secondary                                         no
amber_score_secondary                                        no
minimize_ligand                                              no
atom_model                                                   all
vdw_defn_file                                                ${DOCKPARAMS}/vdw_AMBER_parm99.defn
flex_defn_file                                               ${DOCKPARAMS}/flex.defn
flex_drive_file                                              ${DOCKPARAMS}/flex_drive.tbl
chem_defn_file                                               ${DOCKPARAMS}/chem.defn
pharmacophore_defn_file                                      ${DOCKPARAMS}/ph4.defn
ligand_outfile_prefix                                        ${VENDOR}.output
write_footprints                                             yes
write_hbonds                                                 yes
write_orientations                                           no
num_scored_conformers                                        1
rank_ligands                                                 no
EOF
##################################################


### Write the job batch file
##################################################
cat <<EOF >${SYSTEM}.${VENDOR}.footprint_rescore.slurm
#!/bin/bash
#SBATCH -J ${SYSTEM}.${VENDOR}           # Job name
#SBATCH -o ${SYSTEM}.${VENDOR}.o%j       # Name of stdout output file
#SBATCH -e ${SYSTEM}.${VENDOR}.e%j       # Name of stderr error file
#SBATCH -p skx-normal             # Queue (partition) name
#SBATCH -N 1                      # Total # of nodes 
#SBATCH -n 48                     # Total # of mpi tasks
#SBATCH -t 18:00:00               # Run time (hh:mm:ss)
#SBATCH -A DOCK-at-TACC           # Allocation name (req'd if you have more than 1)

# Launch MPI code... 

cd ${ROOTDIR}/${SYSTEM}/008.footprint-rescore/${VENDOR}/

${DOCKDIR}/dock6 -v -i ${SYSTEM}.${VENDOR}.reference_minimization.in \
                    -o ${SYSTEM}.${VENDOR}.reference_minimization.out

mv output_scored.mol2 ${SYSTEM}.lig.min.mol2

ibrun ${DOCKDIR}/dock6.mpi -v -i ${SYSTEM}.${VENDOR}.footprint_rescore.in \
                              -o ${SYSTEM}.${VENDOR}.footprint_rescore.out

EOF
##################################################


### Submit the job
echo "Submitting ${SYSTEM}.${VENDOR}.footprint_rescore"
sbatch ${SYSTEM}.${VENDOR}.footprint_rescore.slurm


exit

