#! /bin/bash

## the following script can be used to run the prf analysis using vistasoft on the HPC cluster
## using the command 'sbatch run_prf.sh <subjectname> <sessionname>'

## First we set up some SBATCH directives. Note that these are hard values
## if you go beyond your job will be killed by SLURM

#SBATCH --job-name=retinotopy
#SBATCH -a 0  # run this script as 2 jobs with SLURM_ARRAY_TASK_ID = 0 and 1. Add more numbers for more jobs!
#SBATCH --nodes=1 # nodes per job
#SBATCH --cpus-per-task=16
#SBATCH --mem=32g # More memory you request the less priority you get
#SBATCH --time=48:00:00 # should take about 12-24 hours

# Exit upon any error
set -euo pipefail

# Get the path to the directory - the GLM scripts folder
#DIRN=`dirname $0`
DIRN=$SLURM_SUBMIT_DIR

# Ensure exactly two arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Expected 2 arguments. <subject> <session>"
    exit 1
fi

# Assign inputs
subj="$1"
ses="$2"

source $DIRN/setup.sh "$subj" "$ses"

# call the matlab script prepare_data_run_prf.m which identifies bar and wedge runs, averages each and saves out .mat file, then runs prfVista()

logName="preparerun_prf_$(date +%Y%m%d).log"
logFolder=${LOG_DIR}
mkdir -p $logFolder

echo "For details on prepare_data_run_pRF.m check preparerun_prf log file in this directory ..."

matlab -nodisplay -nodesktop -nosplash -noFigureWindows -r "run('${DIRN}/Subroutines/prepare_data_run_pRF.m'); exit;" > ${logFolder}/$logName 2>&1

echo "Completed prfVistaSoft, now creating maps.."

logName="creating_maps_$(date +%Y%m%d).log"

matlab -nodisplay -nodesktop -nosplash -noFigureWindows -r "run('${DIRN}/Subroutines/createmaps.m'); exit;" > ${logFolder}/$logName 2>&1

echo "Completed creating maps."


