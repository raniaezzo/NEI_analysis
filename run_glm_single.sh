#! /bin/bash
#add in the stimfiles and other extras

# Exit upon any error
set -euo pipefail

# Check for python environment
python -c 'import PIL, neuropythy, matplotlib' || die "In command line, run <conda activate winawerlab> prior to masterScript."


# Get the path to the directory, defined as NEI_fitGLM
DIRN=`dirname $0`
source $DIRN/setup.sh ${1-}

# Add the protocol requested for the GLM
allowed_protocols=("floc" "mloc")

# Ensure exactly one argument is provided
if [ $# -eq 1 ]; then
    input_protocol="$1"
    
    # Check if the input matches an allowed protocol
    match_found=false
    for protocol in "${allowed_protocols[@]}"; do
        if [[ "$input_protocol" == "$protocol" ]]; then
            match_found=true
            break
        fi
    done

    # If input is not valid, print an error and exit
    if [[ "$match_found" == false ]]; then
        echo "Error: '$input_protocol' is not a valid protocol. Allowed protocols are: ${allowed_protocols[*]}"
        exit 1
    fi

    # Assign valid input to protocol variable
    selected_protocol="$input_protocol"

elif [ $# -eq 0 ]; then
    # If no argument is given, print an error and exit
    echo "Error: No protocol provided. Expected one of: ${allowed_protocols[*]}"
    exit 1

else
    # If more than one argument is provided, print an error and exit
    echo "Error: Too many arguments. Only one protocol is allowed. Expected one of: ${allowed_protocols[*]}"
    exit 1
fi


# Print tasks for debugging
PROTOCOL=$selected_protocol
export PROTOCOL
echo "PROTOCOL: $selected_protocol"

logName="glm_$(date +%Y%m%d)_$(IFS=_; echo "$PROTOCOL")"
logFolder=${LOG_DIR}/$logName
mkdir -p $logFolder

matlab -nodisplay -nodesktop -nosplash -noFigureWindows -r "run ./subroutines/run_glm_single.m; exit;" > ${logFolder}/glmSingle.log 2>&1
