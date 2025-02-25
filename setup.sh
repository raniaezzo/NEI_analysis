## Export the path to the download data

# Where does code live?
CODE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Source the subroutines
source "$CODE_DIR"/Subroutines/utils.sh

# Define workspace variables

# if called without an argument, check to see whether `module` is found on your path (i.e., we're on a cluster (probably)).
if [[ "$(on_cluster)" == "TRUE" ]] # 
then
    # else, set PROJECT_DIR to a directory in the user's scratch
    # directory
    PROJECT_DIR="/scratch/projects/corevisiongrantnei"    
    SINGULARITY_PULLFOLDER="$CODE_DIR/Singularity" 
    mkdir -p $SINGULARITY_PULLFOLDER 
    load_modules

else
    # set PROJECT_DIR to a subfolder of directory that contains
    # this file. we use some gobblegook from stack overflow as a means to
    # find the directory containing the current function:
    # https://stackoverflow.com/a/246128
    PROJECT_DIR="/Users/rje257/Desktop/transfer_gate"    
    SINGULARITY_PULLFOLDER=""
fi


# Path to BIDS directory
BIDS_DIR="$PROJECT_DIR/NEI_BIDS/"
# create the necessary directories, just to be safe
mkdir -p $PROJECT_DIR 
mkdir -p $BIDS_DIR

# BIDS specific variables
SUBJECT_ID=wlsubj127
SESSION_ID=nyu3t02
LOG_DIR=${BIDS_DIR}/derivatives/logs/sub-${SUBJECT_ID}
SUBJECTS_DIR=${BIDS_DIR}/derivatives/freesurfer/

# Which container software to use 
CONTAINER_SOFTWARE=`which_software`

export SUBJECT_ID
export SESSION_ID
export PROJECT_DIR
export BIDS_DIR
export SUBJECTS_DIR
export LOG_DIR
export CODE_DIR
export CONTAINER_SOFTWARE
export SINGULARITY_PULLFOLDER

echo "*******DEFINE VARIABLES*******"
echo "SUBJECT_ID: $SUBJECT_ID"
echo "SESSION_ID: $SESSION_ID"
echo "PROJECT_DIR: $PROJECT_DIR"
echo "BIDS_DIR: $BIDS_DIR"
echo "SUBJECTS_DIR: $SUBJECTS_DIR"
echo "LOG_DIR: $LOG_DIR"
echo "CODE_DIR: $CODE_DIR"
echo "CONTAINER_SOFTWARE: $CONTAINER_SOFTWARE"
echo "SINGULARITY_PULLFOLDER: ${SINGULARITY_PULLFOLDER-empty}"

# debug
#  echo $CLUSTER 
#  echo $(on_cluster)
# exit 0
