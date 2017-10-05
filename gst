. .paths

GIT_DIR_STRING=$(git rev-parse --git-dir 2>/dev/null)
if [ "$GIT_DIR_STRING" == "" ];
  then
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

LINE=$(expr $1 2>/dev/null)

# the second sed command reverses the order. The awk command removes duplicates via associative array.
IFS=$'\n'
GIT_STATUS=`git status -s | awk '{print $0}'`
GIT_MODIFIER=`git status -s | awk '{print $1}'`
GIT_FILE_PATH=`git status -s | awk '{print $2}'`

# Turn glob expansion off
set -f
STATUS_LINES=($GIT_STATUS)
MODIFIERS=($GIT_MODIFIER)
FILE_PATHS=($GIT_FILE_PATH)

TMP_COUNT=0

while getopts ":a:r:c:" opt; do
  case "${opt}" in
    a)
      `git add $(gst $OPTARG)`
      ;;
    r)
      `git reset HEAD $(gst $OPTARG)`
      ;;
    c)
      `git checkout HEAD $(gist $OPTARG)`
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit -1
      ;;
  esac
done

# Used to determine if the parameter is an integer
SELECT_NUM=`echo "$1" | grep -E ^\-?[0-9]*\.?[0-9]+$`

if [ "$1" == "" ];
    then
    if [ "$GIT_FILE_PATH" == "" ];
        then
            echo "No modified files";
    else
        for MODIFIER in "${MODIFIERS[@]}"
        do
          INDEX_MOD="${STATUS_LINES[${TMP_COUNT}]:0:1}"
          WORK_TREE_MOD="${STATUS_LINES[${TMP_COUNT}]:1:2}"
          DESCRIPTION=""
          COLOUR=""
          if [ "${MODIFIER}" == "M" ];
            then
              DESCRIPTION="Modified"
          elif [ "${MODIFIER}" == "A" ];
            then
              DESCRIPTION="Added"
          elif [ "${MODIFIER}" == "D" ];
            then
              DESCRIPTION="Deleted"
          elif [ "${MODIFIER}" == "R" ];
            then
              DESCRIPTION="Renamed"
          elif [ "${MODIFIER}" == "C" ];
            then
              DESCRIPTION="Copied"
          elif [ "${MODIFIER}" == "U" ];
            then
              DESCRIPTION="Unmerged"
          elif [ "${MODIFIER}" == "??" ];
            then
              DESCRIPTION="Untracked"
          elif [ "${MODIFIER}" == "!!" ];
            then
              DESCRIPTION="Ignored"
          fi
          if [ "${WORK_TREE_MOD:0:1}" == "${MODIFIER:0:1}" ];
            then
              COLOUR_FLAG="-r"
          elif [ "${INDEX_MOD:0:1}" == "${MODIFIER:0:1}" ];
            then
              COLOUR_FLAG="-g"  
          fi
          highlight -v "DESCRIPTION" "$COLOUR_FLAG" "${DESCRIPTION}"

          # nice formatting
          NUMBER_DISP=$(echo "${TMP_COUNT}. $(printf '%.0s ' {1..50})" | head -c 5)
          DESCRIPTION=$(echo "${DESCRIPTION}  $(printf '%.0s ' {1..50})" | head -c 25)
          FILE_PATH="${FILE_PATHS[${TMP_COUNT}]}"
          highlight -v "FILE_PATH" "$COLOUR_FLAG" "${FILE_PATH}"
          echo -e "${NUMBER_DISP}${DESCRIPTION}${FILE_PATH}  (${TMP_COUNT})"
          TMP_COUNT=$(expr $TMP_COUNT + 1)
        done
    fi
elif [ "$SELECT_NUM" -le "${#MODIFIERS[@]}" ];
    then 
        echo "${FILE_PATHS[$1]}";
else
    echo "Invalid selection, unable to reference";
    exit -1;
fi