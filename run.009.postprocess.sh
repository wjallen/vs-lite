#!/bin/bash
#
# This script will postprocess the output files from virtual screening. Briefly,
# it generates a ranked csv file consisting of ZINC ids and other descriptors,
# clusters by fingerprint, and writes some final output mol2 files ranked by 
# different scoring functions. It is these files that should be visually
# inspected for purchasing.
#


### Set some paths
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/run.vars.sh"


### Check to see if the footprint resocred molecules exists
if [ ! -e ${ROOTDIR}/${SYSTEM}/008.footprint-rescore/${VENDOR}/${VENDOR}.output_scored.mol2 ]; then
	echo "You have to rescore with footprint score first. Exiting."
	exit
fi


### Make the appropriate directory
if [ ! -e ${ROOTDIR}/${SYSTEM}/009.postprocess ]; then
	mkdir -p ${ROOTDIR}/${SYSTEM}/009.postprocess
fi

rm -fr ${ROOTDIR}/${SYSTEM}/009.postprocess/${VENDOR}
mkdir -p ${ROOTDIR}/${SYSTEM}/009.postprocess/${VENDOR}
cd ${ROOTDIR}/${SYSTEM}/009.postprocess/${VENDOR}


### Write the job batch file
##################################################
cat <<EOF >${SYSTEM}.${VENDOR}.postprocess.slurm
#!/bin/bash
#SBATCH -J ${SYSTEM}.${VENDOR}           # Job name
#SBATCH -o ${SYSTEM}.${VENDOR}.o%j       # Name of stdout output file
#SBATCH -e ${SYSTEM}.${VENDOR}.e%j       # Name of stderr error file
#SBATCH -p skx-normal             # Queue (partition) name
#SBATCH -N 1                      # Total # of nodes 
#SBATCH -n 1                     # Total # of mpi tasks
#SBATCH -t 06:00:00               # Run time (hh:mm:ss)
#SBATCH -A DOCK-at-TACC           # Allocation name (req'd if you have more than 1)

cd ${ROOTDIR}/${SYSTEM}/009.postprocess/${VENDOR}/

### Link the relevant files here
ln -s ${ROOTDIR}/${SYSTEM}/008.footprint-rescore/${VENDOR}/${VENDOR}.output_scored.mol2 ./${SYSTEM}.${VENDOR}.total.mol2
ln -s ${ROOTDIR}/${SYSTEM}/008.footprint-rescore/${VENDOR}/${VENDOR}.output_footprint_scored.txt ./${SYSTEM}.${VENDOR}.total_fp.txt
cp ${ZINCDIR}/${VENDOR}/num_rot_bonds.dat ./num_rot_bonds.dat


### Check for any duplicate ZINC names, only keep the molecule with the best continuous score 
perl ${UTILSDIR}/remove_duplicate_mol2s.pl ${SYSTEM}.${VENDOR}.total.mol2 ${SYSTEM}.${VENDOR}.total_fp.txt ${SYSTEM}.${VENDOR}.unique.mol2 ${SYSTEM}.${VENDOR}.unique_fp.txt


### Get scores and descriptors from docked mol2, sort by continuous score, and save top "MAX_NUM"
### (duplicates are also removed at this stage)
python ${UTILSDIR}/dock_to_csv.py small ${SYSTEM}.${VENDOR}.unique.mol2 num_rot_bonds.dat ${MAX_NUM} ${SYSTEM}.${VENDOR}
mv ${SYSTEM}.${VENDOR}_sorted_contScore_${MAX_NUM}_small.csv ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_dock.csv


### Generate ranked list of ZINC ids with at most MAX_NUM molecules
cat ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_dock.csv | awk -F "," '{print \$1}' > ${SYSTEM}.${VENDOR}.${MAX_NUM}.codes_withheading.txt
sed '1d' ${SYSTEM}.${VENDOR}.${MAX_NUM}.codes_withheading.txt > ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_codes.txt


### Chop up the unique mol2 into individual files, then concatenate them in the order of the ranked list
mkdir -p ${SCRATCHDIR}
ln -s ${SCRATCHDIR} ./scratch
mv ${SYSTEM}.${VENDOR}.unique.mol2 scratch/
mv ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_codes.txt scratch/
cd scratch/
for NUM in {000..999}; do mkdir \${NUM}; done
python ${UTILSDIR}/break_into_mol.py ${SYSTEM}.${VENDOR}.unique.mol2


for MOL in \` cat ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_codes.txt \`
do
	cat \${MOL:(-3)}/\${MOL}.mol2 >> ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_dock.mol2
done

for NUM in {000..999}; do rm -f \${NUM}/* && rmdir \${NUM}; done

cd ../
mv scratch/${SYSTEM}.${VENDOR}.unique.mol2 ./
mv scratch/${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_dock.mol2 ./
mv scratch/${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_codes.txt ./
python ${UTILSDIR}/dock_to_csv.py full ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_dock.mol2 num_rot_bonds.dat ${MAX_NUM} ${SYSTEM}.${VENDOR}
mv ${SYSTEM}.${VENDOR}_sorted_contScore_all.csv ${SYSTEM}.${VENDOR}.final_sorted_dce_sum.csv

# sort by different things
cat ${SYSTEM}.${VENDOR}.final_sorted_dce_sum.csv | sort -t, -nk8 > ${SYSTEM}.${VENDOR}.final_sorted_fps_sum.csv
cat ${SYSTEM}.${VENDOR}.final_sorted_dce_sum.csv | sort -t, -nk12 > ${SYSTEM}.${VENDOR}.final_sorted_desc_score.csv
# May need to edit the output files to move header to top row



##################################################
# Old descriptors formerly from MOE
#[ 'Weight', 'b_rotN', 'lip_don', 'lip_acc', 'lip_druglike', 'lip_violation',
#  'SlogP', 'FCharge', 'logS', 'chiral', 'SMILES', 'CLUSTER_NO' ] 

##################################################

# Combine csvs
#python ${UTILSDIR}/sort_and_save_updated.py ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_dock.csv ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_moe.csv ${SYSTEM}.${VENDOR}.final



rm scratch 
rm ${SYSTEM}.${VENDOR}.sorted_dce_sum_${MAX_NUM}_codes.txt
rm ${SYSTEM}.${VENDOR}_sorted_contScore_all.csv 
rm ${SYSTEM}.${VENDOR}.${MAX_NUM}.codes_withheading.txt
rm ${SYSTEM}.${VENDOR}.total.mol2 ${SYSTEM}.${VENDOR}.total_fp.txt
exit

EOF
##################################################


### Submit the script
echo "Submitting ${SYSTEM}.${VENDOR}.postprocess.slurm"
sbatch ${SYSTEM}.${VENDOR}.postprocess.slurm


exit


