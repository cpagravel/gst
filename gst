. .paths
GIT_DIR_STRING=$(git rev-parse --git-dir 2>/dev/null)
if [ "$GIT_DIR_STRING" == "" ]; then
  echo "fatal: Not a git repository";
  exit -1
fi

# usage highlight -v variable_name [-g/r/y | text]
highlight()
{
  RED="\e[31m"
  GREEN="\e[32m"
  YELLOW="\e[33m"
  LIGHTRED="\e[91m"
  LIGHTGREEN="\e[92m"
  LIGHTYELLOW="\e[93m"
  DEFAULT="\e[m"

  RESULT_STRING=""
  while getopts ":v:r:y:g:" opt; do
    case "${opt}" in
      v)
        declare -n RETURN_VAL=$OPTARG
        ;;
      r)
        RESULT_STRING="${RED}$OPTARG${DEFAULT}"
        ;;
      y)
        RESULT_STRING="${YELLOW}$OPTARG${DEFAULT}"
        ;;
      g)
        RESULT_STRING="${GREEN}$OPTARG${DEFAULT}"
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        exit -1
        ;;
    esac
  done
  RETURN_VAL=$RESULT_STRING

  # Reset optind to beable to use getopts again
  OPTIND=1
}

usage()
{
gst_filename=$(basename $0)
echo -e "usage: ${gst_filename} [ [ -a | -c | -r | -d ] REF_NUM  | -v ]

  -v                  show the full paths of the files instead of just the file name

  REF_NUM             print the path of the file referenced by REF_NUM

  -a REF_NUM          eq to \e[32mgit add \e[31m<file>\e[m where \e[31m<file>\e[m is replaced with referenced file of REF_NUM

  -r REF_NUM          eq to \e[32mgit reset HEAD \e[31m<file>\e[m where \e[31m<file>\e[m is replaced with the referenced file of REF_NUM

  -c REF_NUM          eq to \e[32mgit checkout HEAD \e[31m<file>\e[m where \e[31m<file>\e[m is replaced with the referenced file of REF_NUM

  -d REF_NUM          eq to \e[32mgit diff HEAD \e[31m<file>\e[m where \e[31m<file>\e[m is replaced with the referenced file of REF_NUM
"
}

LINE=$(expr $1 2>/dev/null)

# the second sed command reverses the order. The awk command removes duplicates via associative array.
IFS=$'\n'
GIT_STATUS=`git status -s | awk '{print $0}'`
GIT_MODIFIER=`git status -s | awk '{print $1}'`
GIT_FILE_PATH=`git status -s | awk -v q="\"" '{gsub(/"/, "", $0); print substr($0, index($0,$2));}'`
# Turn glob expansion off
set -f
STATUS_LINES=($GIT_STATUS)
MODIFIERS=($GIT_MODIFIER)
FILE_PATHS=($GIT_FILE_PATH)
FILE_NAMES=($(echo "$GIT_FILE_PATH" | awk '{print "\""$0"\""}' | xargs -l basename 2>/dev/null))
TMP_COUNT=0

# flags for parsing arguments
VERBOSE_FLAG=false
CALL_MENU_FLAG=false

call_menu()
{
  if [ $VERBOSE_FLAG = true ]; then
      gst -v
    else
      gst
  fi
}

# First pass. Executions handled
while getopts ":a:r:c:d:D:v" opt; do
  case "${opt}" in
    v)
      FILE_NAMES=("${FILE_PATHS[@]}")
      VERBOSE_FLAG=true
      ;;
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
    D)
      IFS=','
      TEMP_LIST=($OPTARG)
      for ref_num in "${TEMP_LIST[@]}"
      do
        rm "${FILE_PATHS[$ref_num]}" &>/dev/null
      done
      ;;
    d)
      echo $(gst $OPTARG)
      git diff HEAD $(gst $OPTARG)
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit -1
      ;;
  esac
done
# Reset optind to beable to use getopts again
OPTIND=1

# Execution loop to parse specific functions
while getopts ":a:r:c:d:v" opt; do
  case "${opt}" in
    a | r | c)
      call_menu
      exit 0;
      ;;
    d)
      exit 0;
      ;;
  esac
done
OPTIND=1

# Used to determine if the parameter is an integer
SELECT_NUM=$(echo "$1" | grep -oP '^(\d+)$')

if [ "$1" == "" ] || [ "$1" == "-v" ]; then
    if [ "$GIT_FILE_PATH" == "" ]; then
            git status;
    else
        for MODIFIER in "${MODIFIERS[@]}"
        do
          INDEX_MOD="${STATUS_LINES[${TMP_COUNT}]:0:1}"
          WORK_TREE_MOD="${STATUS_LINES[${TMP_COUNT}]:1:2}"
          DESCRIPTION=""
          COLOUR=""
          if [ "${MODIFIER:0:1}" == "M" ]; then
              DESCRIPTION="Modified"
          elif [ "${MODIFIER:0:1}" == "A" ]; then
              DESCRIPTION="Added"
          elif [ "${MODIFIER:0:1}" == "D" ]; then
              DESCRIPTION="Deleted"
          elif [ "${MODIFIER:0:1}" == "R" ]; then
              DESCRIPTION="Renamed"
          elif [ "${MODIFIER:0:1}" == "C" ]; then
              DESCRIPTION="Copied"
          elif [ "${MODIFIER:0:1}" == "U" ]; then
              DESCRIPTION="Unmerged"
          elif [ "${MODIFIER:0:1}" == "?" ]; then
              DESCRIPTION="Untracked"
          elif [ "${MODIFIER:0:1}" == "!" ]; then
              DESCRIPTION="Ignored"
          fi
          if [ "${WORK_TREE_MOD:0:1}" == "${MODIFIER:0:1}" ]; then
              COLOUR_FLAG="-r"
          elif [ "${INDEX_MOD:0:1}" == "${MODIFIER:0:1}" ]; then
              COLOUR_FLAG="-g"  
          fi
          highlight -v "DESCRIPTION" "$COLOUR_FLAG" "${DESCRIPTION}"

          # nice formatting
          NUMBER_DISP=$(echo "${TMP_COUNT}. $(printf '%.0s ' {1..50})" | head -c 5)
          DESCRIPTION=$(echo "${DESCRIPTION}  $(printf '%.0s ' {1..50})" | head -c 25)
          FILE_PATH="${FILE_NAMES[${TMP_COUNT}]}"
          highlight -v "FILE_PATH" "$COLOUR_FLAG" "${FILE_PATH}"
          echo -e "${NUMBER_DISP}${DESCRIPTION}${FILE_PATH}  (${TMP_COUNT})"
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