. .paths
GIT_DIR_STRING=$(git rev-parse --git-dir 2>/dev/null)
if [ "$GIT_DIR_STRING" == "" ]; then
  echo "fatal: Not a git repository";
  exit -1
fi

function Trim_to_length() {
  echo "${1}$(printf '%.0s ' {1..50})" | head -c $(expr $2)
}

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
MAGENTA=$(tput setaf 5)
YELLOW=$(tput setaf 226)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# RED="\033[31m"
# GREEN="\033[32m"
# YELLOW="\033[33m"
# LIGHTRED="\033[91m"
# LIGHTGREEN="\033[92m"
# LIGHTYELLOW="\033[93m"
# DEFAULT="\033[m"

Usage()
{
gst_filename=$(basename $0)
echo -e "usage: ${gst_filename} [<-a|-r|-c|-d|-D> <REF_NUM>] [REF_NUM] [-A] [-v] [-u]

  -a REF_NUM          eq to ${GREEN}git add ${RED}<file>${RESET} where ${RED}<file>${RESET} is replaced with referenced file of REF_NUM

  -r REF_NUM          eq to ${GREEN}git reset HEAD ${RED}<file>${RESET} where ${RED}<file>${RESET} is replaced with the referenced file of REF_NUM

  -c REF_NUM          eq to ${GREEN}git checkout HEAD ${RED}<file>${RESET} where ${RED}<file>${RESET} is replaced with the referenced file of REF_NUM

  -d REF_NUM          eq to ${GREEN}git diff HEAD ${RED}<file>${RESET} where ${RED}<file>${RESET} is replaced with the referenced file of REF_NUM
  
  -D REF_NUM          eq to ${GREEN}rm ${RED}<file>${RESET} where ${RED}<file>${RESET} is replaced with the referenced file of REF_NUM

  REF_NUM             print the path of the file referenced by REF_NUM

  -A                  eq to ${GREEN}git add ${RED}-u${RESET}

  -v                  show the full paths of the files instead of just the file name

  -u                  eq to ${GREEN}git add ${RED}-u${RESET}
"
}

LINE=$(expr $1 2>/dev/null)

DISPLAY_LIST=true
VERBOSE_FLAG=false

GenerateList()
{
  # the second sed command reverses the order. The awk command removes duplicates via associative array.
  IFS=$'\n'
  GIT_STATUS=`git status -s | awk '{print $0}'`
  GIT_MODIFIER=`git status -s | awk '{print substr($0,0,2)}'`
  GIT_FILE_PATH=`git status -s | awk -v q="\"" '{gsub(/"/, "", $0); print substr($0, index($0,$2));}'`
  # Turn glob expansion off
  set -f
  STATUS_LINES=($GIT_STATUS)
  MODIFIERS=($GIT_MODIFIER)
  FILE_PATHS=($GIT_FILE_PATH)
  FILE_NAMES=($(echo "$GIT_FILE_PATH" | awk '{print "\""$0"\""}' | xargs -L 1 basename 2>/dev/null))

  TMP_COUNT=0

  if [ "$VERBOSE_FLAG" == true ]; then
    FILE_NAMES=("${FILE_PATHS[@]}")
  fi  
}

# Generate the initial list for operations
GenerateList

# First pass. Executions handled
while getopts ":a:r:c:d:D:Avuh" opt; do
  case "${opt}" in
    a)
      IFS=','
      TEMP_LIST=($OPTARG)
      # for sorting this array in reverse order
      # IFS=$'\n'
      # TEMP_LIST=( $(printf "%s\n" "${TEMP_LIST[@]}" | sort -rn) )
      for ref_num in "${TEMP_LIST[@]}"
      do
        git add "${FILE_PATHS[$ref_num]}" &>/dev/null
      done
      ;;
    r)
      IFS=','
      TEMP_LIST=($OPTARG)
      for ref_num in "${TEMP_LIST[@]}"
      do
        git reset HEAD "${FILE_PATHS[$ref_num]}" &>/dev/null
      done
      ;;
    c)
      IFS=','
      TEMP_LIST=($OPTARG)
      for ref_num in "${TEMP_LIST[@]}"
      do
        git checkout HEAD "${FILE_PATHS[$ref_num]}" &>/dev/null
      done
      ;;
    d)
      ref_num=$(expr $OPTARG 2>/dev/null)
      if ! [ "$ref_num" == "" ]; then
        git diff HEAD "${FILE_PATHS[$ref_num]}"
      fi
      exit 0;
      ;;
    D)
      IFS=','
      TEMP_LIST=($OPTARG)
      for ref_num in "${TEMP_LIST[@]}"
      do
        rm "${FILE_PATHS[$ref_num]}" &>/dev/null
      done
      ;;
    A)
      git add -A
      ;;
    v)
      FILE_NAMES=("${FILE_PATHS[@]}")
      VERBOSE_FLAG=true
      ;;
    u)
      git add -u
      ;;
    h)
      Usage
      exit -1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      Usage
      exit -1
      ;;
  esac
done
# Reset optind to beable to use getopts again
OPTIND=1

# Execution loop to parse specific functions
while getopts "arcdDAvuh" opt; do
  case "${opt}" in
    a | r | c | D | A)
      GenerateList
      ;;
  esac
done
OPTIND=1 

Git_flag_decode() {
  # Standard dev
  if [ "${1:0:1}" == "M" ]; then
      FLAG_RESULT="Modified"
  elif [ "${1:0:1}" == "A" ]; then
      FLAG_RESULT="Added"
  elif [ "${1:0:1}" == "D" ]; then
      FLAG_RESULT="Deleted"
  elif [ "${1:0:1}" == "R" ]; then
      FLAG_RESULT="Renamed"
  elif [ "${1:0:1}" == "C" ]; then
      FLAG_RESULT="Copied"
  elif [ "${1:0:1}" == "U" ]; then
      FLAG_RESULT="Unmerged"
  elif [ "${1:0:1}" == "T" ]; then
      FLAG_RESULT="TypeChg"
  elif [ "${1:0:1}" == "?" ]; then
      FLAG_RESULT="Untrackd"
  elif [ "${1:0:1}" == "!" ]; then
      FLAG_RESULT="Ignored"
  # Submodule case
  elif [ "${1:0:1}" == "m" ]; then
      FLAG_RESULT="Sub Mod"
  fi
  printf "${FLAG_RESULT}"
}

# Used to determine if the parameter is an integer
SELECT_NUM=$(echo "$1" | grep -oP '^(\d+)$')

if [ "$SELECT_NUM" == "" ] && [ "$DISPLAY_LIST" == true ]; then
    if [ "$GIT_FILE_PATH" == "" ]; then
            git status;
    else
        printf "${YELLOW}#   INDEX     CUR_TREE  FILE${RESET}\n"
        for MODIFIER in "${MODIFIERS[@]}"
        do
          # Innermost brackets decode to a string, then trim, then colour
          INDEX_DESC="${GREEN}$(Trim_to_length "$(Git_flag_decode ${MODIFIER:0:1})" 10)${RESET}"
          WORK_TREE_DESC="${RED}$(Trim_to_length "$(Git_flag_decode ${MODIFIER:1:2})" 10)${RESET}"

          NUMBER_DISP=`Trim_to_length "${TMP_COUNT}    " 4`
          FILE_PATH="${FILE_NAMES[${TMP_COUNT}]}"
          echo -e "${MAGENTA}${NUMBER_DISP}${RESET}${INDEX_DESC}${WORK_TREE_DESC}${FILE_PATH}  (${MAGENTA}${TMP_COUNT}${RESET})"
          TMP_COUNT=$(expr $TMP_COUNT + 1)
        done
    fi
elif [ "$SELECT_NUM" != "" ]; then
  if [ "$SELECT_NUM" -le "${#MODIFIERS[@]}" ]; then
    # Remove single quotes on both sides
    temp="${FILE_PATHS[$SELECT_NUM]%\'}"
    temp="${temp#\'}"
    echo "$temp"
  else
    echo "Invalid selection, unable to reference";
    exit -1;
  fi
fi