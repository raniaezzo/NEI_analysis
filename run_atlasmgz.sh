#! /bin/bash

## the following script can be used to run the atlas conversion to native space on the HPC cluster
## using the command 'sbatch run_atlasmgz.sh <subjectname> <sessionname>'

## First we set up some SBATCH directives. Note that these are hard values
## if you go beyond your job will be killed by SLURM

#SBATCH --job-name=atlasmgz
#SBATCH -a 0  # run this script as 2 jobs with SLURM_ARRAY_TASK_ID = 0 and 1. Add more numbers for more jobs!
#SBATCH --nodes=1 # nodes per job
#SBATCH --cpus-per-task=2
#SBATCH --mem=2g # More memory you request the less priority you get
#SBATCH --time=1:00:00 # 

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

sh $DIRN/atlasmgz/createAtlasLabels.sh "$subj" "$BIDS_DIR"
