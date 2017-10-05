. .paths

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
}

GIT_DIR_STRING=$(git rev-parse --git-dir 2>/dev/null)
if [ "$GIT_DIR_STRING" == "" ];
then
    echo "fatal: Not a git repository";
else
    RED="\e[31m"
    GREEN="\e[32m"
    YELLOW="\e[33m"
    LIGHTRED="\e[91m"
    LIGHTGREEN="\e[92m"
    LIGHTYELLOW="\e[93m"
    DEFAULT="\e[m"

    HIGHLIGHT=$LIGHTRED
    NEUTRAL=$LIGHTYELLOW



    LINE=$(expr $1 2>/dev/null)

    # the second sed command reverses the order. The awk command removes duplicates via associative array.
    GIT_MODIFIER=`git status -s | awk '{print $1}'`
    GIT_FILE_PATH=`git status -s | awk '{print $2}'`

    MODIFIERS=${GIT_MODIFIER}
    MODIFIERS=($GIT_MODIFIER)

    FILE_PATHS=${GIT_FILE_PATH}
    FILE_PATHS=($GIT_FILE_PATH)

    TMP_COUNT=0

    if [ "$1" == "" ];
        then
        if [ "$GIT_FILE_PATH" == "" ];
            then
                echo "No modified files";
        else
            for MODIFIER in "${MODIFIERS[@]}"
            do
              DESCRIPTION=""
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
              highlight -v "DESCRIPTION" -g "${DESCRIPTION}"

              echo -e "${TMP_COUNT}. $DESCRIPTION ${FILE_PATHS[${TMP_COUNT}]}"
              TMP_COUNT=$(expr $TMP_COUNT + 1)
            done
        fi
    # elif [ "$1" == "0" ];
        # then
            # git checkout HEAD
    # elif [ "${#MATCHES[@]}" == 1 ];
        # then
            # git checkout "${MATCHES[$LINE]}"
    elif [ "$1" -le "${#MODIFIERS[@]}" ];
        then 
            echo "${FILE_PATHS[$1]}";
    else
        echo "Invalid selection, unable to reference";
        exit -1;
    fi
fi