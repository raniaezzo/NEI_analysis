#!/bin/bash

## The following script runs ses-nyu3t01 retinotopy, and ses-nyu3t02 floc/mloc GLMs using GLMsingle on the HPC cluster
## Usage: sh masterScript.sh -subjects wlsubj120 wlsubj121 -sessions nyu3t01 nyu3t02
## or to run all sessions for all subjects:  sh masterScript.sh -subjects all -sessions all

# Initialize arrays
subjects=()
sessions=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -subjects)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                subjects+=("$1")
                shift
            done
            ;;
        -sessions)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                sessions+=("$1")
                shift
            done
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Locate the NEI_BIDS directory
NEI_BIDS_DIR=$(find ../.. -maxdepth 2 -type d -name "NEI_BIDS" -print -quit)

if [ -z "$NEI_BIDS_DIR" ]; then
    echo "Error: NEI_BIDS directory not found. Ensure this script is within 2 parent directories from the NEI_BIDS folder."
    exit 1
fi

# Determine which subjects to process
if [ "$subjects" == "all" ]; then
    subjects=()
    for dir in "$NEI_BIDS_DIR/derivatives/fmriprep"/sub-*; do
        if [ -d "$dir" ]; then
            sub=${dir##*/sub-}
            subjects+=("$sub")
        fi
    done
fi

if [ "$sessions" == "all" ]; then
    sessions=("nyu3t01" "nyu3t02")
fi

# Debug print
echo "Subjects: ${subjects[@]}"
echo "Sessions: ${sessions[@]}"

for ses in "${sessions[@]}"; do
    for sub in "${subjects[@]}"; do
        SESSION_DIR="$NEI_BIDS_DIR/derivatives/fmriprep/sub-$sub/ses-$ses"
        FUNC_DIR="$SESSION_DIR/func"

        # Check if session directory exists
        if [ ! -d "$SESSION_DIR" ]; then
            echo "Skipping $sub: fMRIprep directory $SESSION_DIR does not exist."
            continue
        fi

        if [ "$ses" == "nyu3t02" ]; then   # localizer is in ses2
            for protocol in floc mloc; do
                # Get the BIDS protocol name from JSON
                bidsprotocolname=$(jq -r ".protocols.$protocol.bids_task_name" localizers_params.json)

                # Check if protocol files exist
                if ! ls "$FUNC_DIR"/*task-"$bidsprotocolname"* 1> /dev/null 2>&1; then
                    echo "Skipping $sub $protocol: No files with task-$bidsprotocolname found in $FUNC_DIR."
                    continue
                fi

                # Uncomment these lines for actual job submission
                var1="$NEI_BIDS_DIR/derivatives/logs/sub-$sub/%x-$session-%a.err"
                var2="$NEI_BIDS_DIR/derivatives/logs/sub-$sub/%x-$session-%a.out"
                #job_id=$(sbatch --job-name="$sub-$protocol" --error="$var1" --output="$var2" run_glm_single.sh "$protocol" "$sub" "$session" | awk '{print $NF}')
                #echo "Submitted $sub $protocol as batch job with Job ID: $job_id"
            done

        elif [ "$ses" == "nyu3t01" ]; then  # retinotopy is in ses1

            # Convert atlas to native space (does not require functional runs)
            var1="$NEI_BIDS_DIR/derivatives/logs/sub-$sub/%x-atlasconv-%a.err"
            var2="$NEI_BIDS_DIR/derivatives/logs/sub-$sub/%x-atlasconv-%a.out"
            job_id=$(sbatch --job-name="$sub-atlasconv" --error="$var1" --output="$var2" run_atlasmgz.sh "$sub" "$ses" | awk '{print $NF}')
            echo "Submitted atlas conversion for $sub" 

            # Check if protocol files exist
            if ! ls "$FUNC_DIR"/*task-{bar,wedgering}* 1> /dev/null 2>&1; then
                echo "Skipping $sub retinotopy: No files with *task-bar* or *task-wedgering* found in $FUNC_DIR."
                continue
            fi

            # Uncomment these lines for actual job submission
            var1="$NEI_BIDS_DIR/derivatives/logs/sub-$sub/%x-$ses-%a.err"
            var2="$NEI_BIDS_DIR/derivatives/logs/sub-$sub/%x-$ses-%a.out"
            job_id=$(sbatch --job-name="$sub-retinotopy" --error="$var1" --output="$var2" run_prf.sh "$sub" "$ses" | awk '{print $NF}')
            echo "Submitted retinotopy for $sub"

        else
            echo "Error: NEI_BIDS directory not found. Ensure this script is within 2 parent directories from the NEI_BIDS folder."
            exit 1
	fi

    done
done

exit 0
