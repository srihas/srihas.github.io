#!/bin/bash

declare -r DOTFILES_TARBALL=srihas_dev_dotfiles.tar.gz
declare -r DOTFILES_UTILS=utils.sh

declare -r DOTFILES_TARBALL_URL="http://srihas.github.io/assets/download/dotfiles_install/$DOTFILES_TARBALL"
declare -r DOTFILES_UTILS_URL="http://srihas.github.io/assets/download/dotfiles_install/$DOTFILES_UTILS"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare dotfilesDirectory="$HOME/dotfiles"
declare skipQuestions=false

# ----------------------------------------------------------------------
# | Helper Functions                                                   |
# ----------------------------------------------------------------------

download() {

    local url="$1"
    local output="$2"

    if command -v "curl" &> /dev/null; then

        curl -LsSo "$output" "$url" &> /dev/null
        #     │││└─ write output to file
        #     ││└─ show error messages
        #     │└─ don't show the progress meter
        #     └─ follow redirects

        return $?

    elif command -v "wget" &> /dev/null; then

        wget -qO "$output" "$url" &> /dev/null
        #     │└─ write output to file
        #     └─ don't show output

        return $?
    fi

    return 1

}

download_utils() {

    local tmpFile=""

    tmpFile="$(mktemp /tmp/XXXXX)"

    download "$DOTFILES_UTILS_URL" "$tmpFile" \
        && . "$tmpFile" \
        && rm -rf "$tmpFile" \
        && return 0

   return 1

}

download_dotfiles() {

    local tmpFile=""
    local isDownloaded=False

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    print_in_yellow "Checking if $DOTFILES_TARBALL already exists\n"
    if [ -f "$DOTFILES_TARBALL" ]; then
        print_in_yellow "$DOTFILES_TARBALL already exist, not downloading\n"
        tmpFile="$DOTFILES_TARBALL"
    else

        print_in_purple "\n • Download and extract archive\n\n"

        tmpFile="$(mktemp /tmp/XXXXX)"

        download "$DOTFILES_TARBALL_URL" "$tmpFile"
        print_result $? "Download archive" "true"
        isDownloaded=True
        printf "\n"
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ! $skipQuestions; then

        ask_for_confirmation "Do you want to store the dotfiles in '$dotfilesDirectory'?"

        if ! answer_is_yes; then
            dotfilesDirectory=""
            while [ -z "$dotfilesDirectory" ]; do
                ask "Please specify another location for the dotfiles (path): "
                dotfilesDirectory="$(get_answer)"
            done
        fi

        # Ensure the `dotfiles` directory is available

        while [ -e "$dotfilesDirectory" ]; do
            ask_for_confirmation "'$dotfilesDirectory' already exists, do you want to overwrite it?"
            if answer_is_yes; then
                rm -rf "$dotfilesDirectory"
                break
            else
                dotfilesDirectory=""
                while [ -z "$dotfilesDirectory" ]; do
                    ask "Please specify another location for the dotfiles (path): "
                    dotfilesDirectory="$(get_answer)"
                done
            fi
        done

        printf "\n"

    else

        rm -rf "$dotfilesDirectory" &> /dev/null

    fi

    mkdir -p "$dotfilesDirectory"
    print_result $? "Create '$dotfilesDirectory'" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Extract archive in the `dotfiles` directory.

    extract "$tmpFile" "$dotfilesDirectory"
    print_result $? "Extract archive" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if [ $isDownloaded = True ];then
        rm -rf "$tmpFile"
        print_result $? "Remove archive"
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}


extract() {

    local archive="$1"
    local outputDir="$2"

    if command -v "tar" &> /dev/null ; then
        tar -zxf "$archive" --strip-components 1 -C "$outputDir"
        return $?
    fi

    return 1

}

verify_os() {

    declare -r MINIMUM_UBUNTU_VERSION="16.04"

    local os_name="$(get_os)"
    local os_version="$(get_os_version)"

    
    # Check if the OS is `Ubuntu` and
    # it's above the required version.

    if [ "$os_name" == "ubuntu" ]; then

        if is_supported_version "$os_version" "$MINIMUM_UBUNTU_VERSION"; then
            return 0
        else
            printf "Sorry, this script is intended only for Ubuntu %s+" "$MINIMUM_UBUNTU_VERSION"
        fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    elif [ "$os_name" == "sles" ];then
	return 0
    else
        printf "Sorry, this script is intended only for Ubuntu,SLES!"
    fi

    return 1

}

create_bash_env() {
    declare -r FILE_PATH="$dotfilesDirectory/.bash.env"
    local status=1

    if [ ! -e "$FILE_PATH" ] || [ -z "$FILE_PATH" ]; then
        printf "%s\n" \
    "
# ----------------------------------------------------------------------------------------------
# General
# ----------------------------------------------------------------------------------------------


# Mandatory properties to update
# MY_HOME
#       Point to your home directory location for storing backups and other utils etc
# DOT_FOLDER
#       Point to dotfiles directory location


export MY_HOME=\"\$HOME\"
export DOT_FOLDER=$dotfilesDirectory

# Folder name with its dot configurations
export DOT_PROFILES=\"dev-env\"

export LOG_LEVEL=\"DEBUG\"

    " \
        >> "$FILE_PATH"
    status=0
   else
        print_in_yellow "   Skipping generation of $FILE_PATH, already exists !\n"
   fi

    print_result $status "Generated Bash environment configuration file: $FILE_PATH"
}

create_bash_local() {

    declare -r FILE_PATH="$HOME/.bash.local"
    local status=1
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   if [ ! -e "$FILE_PATH" ] || [ -z "$FILE_PATH" ]; then
        DOTFILES_BIN_DIR="$dotfilesDirectory/bin/"

        printf "%s\n" \
"#!/bin/bash

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set PATH additions.

PATH=\"\$PATH:$DOTFILES_BIN_DIR\"

export PATH

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#export ENV_NAME=DEV
alias dot='cd $dotfilesDirectory'
" \
        >> "$FILE_PATH"
    status=0
   else
        print_in_yellow "   Skipping generation of $FILE_PATH, already exists !\n"
   fi

    print_result $status "$FILE_PATH"

}

create_gitconfig_local() {

    declare -r FILE_PATH="$HOME/.gitconfig.local"
    local status=1
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if [ ! -e "$FILE_PATH" ] || [ -z "$FILE_PATH" ]; then

        printf "%s\n" \
"[commit]

    # Sign commits using GPG.
    # https://help.github.com/articles/signing-commits-using-gpg/

    # gpgsign = true


[user]

    name =
    email =
    # signingkey =" \
        >> "$FILE_PATH"
    status=0
    else
        print_in_yellow "   Skipping generation of $FILE_PATH, already exists !\n"
    fi

    print_result $status "$FILE_PATH"

}

create_vimrc_local() {

    declare -r FILE_PATH="$HOME/.vimrc.local"
    local status=1
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if [ ! -e "$FILE_PATH" ]; then
        printf "" >> "$FILE_PATH"
        status=0
    else
        print_in_yellow "   Skipping generation of $FILE_PATH, already exists !\n"
    fi

    print_result $status "$FILE_PATH"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# ----------------------------------------------------------------------
# | Main                                                               |
# ----------------------------------------------------------------------

main() {

    # Ensure that the following actions
    # are made relative to this file's path.

    cd "$(dirname "${BASH_SOURCE[0]}")" \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Load utils

    if [ -x "$DOTFILES_UTILS" ]; then
        . "$DOTFILES_UTILS" || exit 1
    else
        download_utils || exit 1
    fi
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Ensure the OS is supported and
    # it's above the required version.

    verify_os \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    skip_questions "$@" \
        && skipQuestions=true

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    print_in_yellow "\n\t
   _____      _   _   _                                 _       _    __ _ _           
  / ____|    | | | | (_)                               | |     | |  / _(_) |          
 | (___   ___| |_| |_ _ _ __   __ _   _   _ _ __     __| | ___ | |_| |_ _| | ___  ___ 
  \___ \ / _ \ __| __| | '_ \ / _\` | | | | | '_ \   / _\` |/ _ \| __|  _| | |/ _ \/ __|
  ____) |  __/ |_| |_| | | | | (_| | | |_| | |_) | | (_| | (_) | |_| | | | |  __/\__ \\
 |_____/ \___|\__|\__|_|_| |_|\__, |  \__,_| .__/   \__,_|\___/ \__|_| |_|_|\___||___/
                               __/ |       | |                                        
                              |___/        |_|                                        
    \n\n"

    download_dotfiles
    create_bash_env
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ask_for_confirmation "Configure local config files?"
    if answer_is_yes; then
        print_in_purple "\n • Create local config files\n\n"

        create_bash_local
        create_gitconfig_local
        create_vimrc_local

    fi

    print_in_purple "\n • Update .bashrc or .bash_profile\n\n"

    print_in_green "if [ -f $dotfilesDirectory/.bash.profile ]; then\n"
    print_in_green "    . $dotfilesDirectory/.bash.profile\n"
    print_in_green "fi\n"

    print_in_purple "\n • Source the installed bash profile\n\n"

    print_in_green "   source $dotfilesDirectory/.bash.profile\n"

    print_in_purple "\n • Set ENV_NAME in ~/.bash.local to describe the environment\n\n"

    print_in_green "   export ENV_NAME=DEV\n"

    echo ""
    print_result 0 "Successfully configured dotfiles at [$dotfilesDirectory]\n\n"
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

main "$@"
