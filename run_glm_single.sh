#! /bin/bash

## the following script can be used to run the floc and mloc GLMs using GLMsingle on the HPC cluster
## using the command 'sbatch run_glm_single.sh <protocolname> <subjectname> <sessionname>'

## First we set up some SBATCH directives. Note that these are hard values
## if you go beyond your job will be killed by SLURM

#SBATCH --job-name=localizer
#SBATCH -a 0  # run this script as 2 jobs with SLURM_ARRAY_TASK_ID = 0 and 1. Add more numbers for more jobs!
#SBATCH --nodes=1 # nodes per job
#SBATCH --cpus-per-task=8 
#SBATCH --mem=32g # More memory you request the less priority you get
#SBATCH --time=2:00:00 # should take about 15-45 min per run

# Exit upon any error
set -euo pipefail

# Get the path to the directory - the GLM scripts folder
#DIRN=`dirname $0`
DIRN=$SLURM_SUBMIT_DIR

# Ensure exactly two arguments are provided
if [ $# -ne 3 ]; then
    echo "Error: Expected 3 arguments. <protocol> <subject> <session>"
    exit 1
fi

# Assign inputs
input_protocol="$1"
subj="$2"
ses="$3"

source $DIRN/setup.sh "$subj" "$ses"

# Check for python environment
python -c 'import PIL, neuropythy, matplotlib' || { echo "Error: Conda environment is not activated. Set up winawerlab environment in /scratch/$USER/environments/winawerlab"; exit 1; }

# Add the protocol requested for the GLM
allowed_protocols=("floc" "mloc")

# Validate protocol input
match_found=false
for protocol in "${allowed_protocols[@]}"; do
    if [[ "$input_protocol" == "$protocol" ]]; then
        match_found=true
        break
    fi
done

if [[ "$match_found" == false ]]; then
    echo "Error: '$input_protocol' is not a valid protocol. Allowed protocols are: ${allowed_protocols[*]}"
    exit 1
fi

# Assign valid input to protocol variable
selected_protocol="$input_protocol"

# Print tasks for debugging
export PROTOCOL=$selected_protocol
echo "PROTOCOL: $selected_protocol"

logName="GLMsingle_$(date +%Y%m%d)_$(IFS=_; echo "$PROTOCOL").log"
logFolder=${LOG_DIR}
mkdir -p $logFolder

echo "For details on GLMsingle check GLM subfolder in this log directory ..."

matlab -nodisplay -nodesktop -nosplash -noFigureWindows -r "run('${DIRN}/Subroutines/run_glm_single.m'); exit;" > ${logFolder}/$logName 2>&1

echo "Completed GLM single."
