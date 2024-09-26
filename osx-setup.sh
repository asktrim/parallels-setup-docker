#!/bin/bash

# Run with
# $ chmod +x osx-setup.sh
# $ ./osx-setup.sh

programname=$0

function showManual() {
: << 'COMMENT'
  Available options
COMMENT
    echo "Usage: $programname [--OPTIONSFLAG]"
    printf "\n\n\n"
    echo -e "Available OPTIONSFLAGs.  e.g  ./osx-setup.sh --osx --ruby --zsh"
    echo "[--full=Bootstrap your command line environment (Recommended)]"
    echo "[--osx=MacOSX essentials]"
    echo "[--ruby=devtools]"
    echo "[--zsh=zshell template w/ antigen]"
    echo "[--fzf=Fuzzy finder]"
    echo "[--nvm=Node version manager]"
    echo "[-d debugger]"
    printf "\n\n\n"
}

INSTALL_XCODE=
INSTALL_HOMEBREW=
INSTALL_ZSHRC_TEMPLATE=
INSTALL_ZSHRC_ANTIGEN=
INSTALL_CODE_FROM_GIT=
INSTALL_NVM=
INSTALL_FZF=
FAIL_FAST=
OPTIONS=
INSTALL_TRIM_RUBY_ENV=
EXPRESS_INSTALL=
optspec=":hdav-:"
while getopts "$optspec" OPTION; do
    case ${OPTION} in
    d)
        FAIL_FAST="true"
        ;;
    h)
        OPTIONS="true"
        ;;
    a)  
        EXPRESS_INSTALL="true"
        ;;
    -)
        case ${OPTARG} in
            "osx"*)
              INSTALL_XCODE="true"
              INSTALL_HOMEBREW="true"
              ;;
            "ruby"*) INSTALL_TRIM_RUBY_ENV="true"
              ;;
            "zsh"*)
              INSTALL_ZSHRC_TEMPLATE="true"
              INSTALL_ZSHRC_ANTIGEN="true"
              ;;
            "fzf"*) INSTALL_FZF="true"
              ;;
            "nvm"*) INSTALL_NVM="true"
              ;;
            "help"*) OPTIONS="true"
              ;;
            "full"*) EXPRESS_INSTALL="true"
              ;;
            *)
              echo "Error: Invalid arguments detected."
              exit 1
              ;;
         esac
         ;;
     *)
        echo "Error: Invalid arguments detected."
        exit 1
        ;;
    esac
done

# ------------------------------------------------------------------------------------------------------------------------------------


function clitools() {
: << 'COMMENT'
  Install xcode command line tools if needed
COMMENT
  echo "# Installing xcode command line utils..."
  if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
     test -d "${xpath}" && test -x "${xpath}" ; then
     echo "xcode command line tools already installed"
  else
     xcode-select --install
  fi
  echo "Done."
}

HOMEBREW_SCRIPT="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
function homebrew() {
: << 'COMMENT'
Install Homebrew if no previous installation is found.
COMMENT
  echo "Checking Homebrew...."
  # Install homebrew if not configured
  if test ! $(which brew); then
      /bin/bash -c "$(curl -fsSL $HOMEBREW_SCRIPT)"
  fi

  echo "Upgrade brew and brew formulae"
  brew upgrade
  echo "Done."
}

function zshrcTemplate() {
: << 'COMMENT'
Use .zshrc template (opinionated)
COMMENT
  curl https://raw.githubusercontent.com/laujonat/dotfiles/master/zsh/.zshrc -o ~/.zshrc.local
}

TRIMANALYTICS_DIR="$HOME/workspace/"
TRIMANALYTICS_GIT="git@github.com:asktrim/trimanalytics.git"
function cloneFromGithub() {
: << 'COMMENT'
Configure Trimanalytics from Github.
Requires SSH to be configured with Github.
https://asktrim.slab.com/posts/setup-local-development-with-docker-c7adkq9a
COMMENT
  echo "Creating local workspace directory ~/workspace"
  if [ ! -d $TRIMANALYTICS_DIR ]; then
    mkdir -p $TRIMANALYTICS_DIR
  else
    echo "Directory ~/workspace already exists."
  fi
  echo "Done."
  echo "\n\nCloning trimanalytics from github via SSH"
  if [ ! -d "$TRIMANALYTICS_DIR/trimanalytics" ]; then
    git clone $TRIMANALYTICS_GIT $TRIMANALYTICS_DIR/trimanalytics
  fi

  echo "Done.\n\n"
  copyEnvTemplates
}

ENV_TEMPLATE="$HOME/workspace/trimanalytics/.env.template"
NGROK_TEMPLATE="$HOME/workspace/trimanalytics/ngrok.template.yml"
function copyEnvTemplates() {
  if [ ! -f $HOME/workspace/trimanalytics/.env ]; then
    echo "Copying .env.template to .env\n"
    cp  $HOME/workspace/trimanalytics/.env
    echo "\n\nSee setup local development (with docker) documentation!\n"
    printf '\n\e]8;;https://asktrim.slab.com/posts/setup-local-development-with-docker-c7adkq9a\e\\Docker setup\e]8;;\e\\\n'
    echo "Done.\n\n"
  fi
  if [ ! -f $HOME/workspace/trimanalytics/ngrok.yml ]; then
    echo "Copying ngrok.template.yml to ngrok.yml\n"
    cp $NGROK_TEMPLATE $HOME/workspace/trimanalytics/ngrok.yml
    echo
    echo "For configuration instructions, see documentation:"
    printf '\n\e]8;;https://asktrim.slab.com/posts/set-up-a-local-ngrok-tunnel-auplzxno\e\\This is a link\e]8;;\e\\\n'
    echo "Done.\n\n"
  fi
}

RBENV_PATH="$HOME/.rbenv"
SHIMS_PATH="$RBENV_PATH/shims:$PATH"
function setupRuby() {
: << 'COMMENT'
Configure Ruby environment
COMMENT
  printf '\n\e]8;;https://asktrim.slab.com/posts/install-ruby-2ax9tdag\e\\Installing Ruby as specified in Slab document\e]8;;\e\\\n'

  echo "\n\nInstalling rbenv..."
  rbenv -v
  brew install rbenv
  echo "Done.\n\n"
  echo "Initialize rbenv in current shell\n\n"

  if [ -d $HOME/.rbenv ]; then
    export PATH="$SHIMS_PATH"
    eval "$(rbenv init - zsh)"
  fi
  echo "Done.\n\n"

  echo "# Adding 'eval "$(rbenv init -)"' to profile\n\n"
  echo 'eval "$(rbenv init -zsh)"' >> ~/.zshrc
  echo "Done.\n\n"


  # Required for Macs with M1 chip
  if [[ $(uname -m) == 'arm64' ]]; then
    # https://github.com/ffi/ffi/issues/869#issuecomment-752123090
    echo "# M1 chip detected. Setting RUBY_CFLAGS"
    echo "https://github.com/ffi/ffi/issues/869#issuecomment-752123090"
    export RUBY_CFLAGS=-DUSE_FFI_CLOSURE_ALLOC
  fi

  echo "\n\nInstalling tools globally for Ruby development\n\n"
  cd $TRIMANALYTICS_DIR
  gem install bundler:1.17.3
  separator
  gem install rubocop rubocop-rails rubocop-performance
}

function antigenSetup() {
: << 'COMMENT'
Antigen plugin manager configuration.  Comment out the following lines of code if you prefer another plugin manager.
COMMENT
  echo "\n\nInstalling antigen plugin manager."
  curl -L git.io/antigen > antigen.zsh
  echo "Done."
}

FZF_SCRIPT="https://github.com/junegunn/fzf.git"
FZF_DIR="$HOME/.fzf"
function fzfSetup() {
: << 'COMMENT'
Fuzzy search setup
COMMENT
  echo "\n\nInstall fzf search command line util.  Checking...."
  if [ -d $FZF_DIR ]
  then
      echo "# Warning: fzf already exists."
  else
    git clone --depth 1 $FZF_SCRIPT $FZF_DIR
    ~/.fzf/install
  fi
  echo "Done."
}


NVM_SCRIPT="https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh"
function nvmSetup() {
: << 'COMMENT'
Node version manager (nvm) configuration.
COMMENT
  echo "Install Node Version Manager"
  curl -sL $NVM_SCRIPT -o install_nvm.sh

  printf "\033[91;1mVERIFY INSTALLATION\033[0m\n"
  echo "\n\nexport NVM_DIR=\"$HOME/.nvm\"\n[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\"  # This loads nvm \
    \n[ -s \"$NVM_DIR/bash_completion\" ] && \. \"$NVM_DIR/bash_completion\"  # This loads nvm bash_completion"
}

function separator() {
  echo
  echo "================================================================================"
  echo
}

# -------------------------------------------------------------------------------------------------------------------

: << 'COMMENT'
WARN: This script will run as sudo user.\n
Setting SUDO_USER
COMMENT
separator
printf "\033[91;1mENABLING SUDO PRIVILEGES FOR CURRENT USER\033[0m\n"
  # Setup sudo user (required)
  SUDO_USER=$(whoami)

  if [[ $OPTIONS ]]; then
    separator
    showManual
  fi


if [[ $INSTALL_XCODE ]]; then
  separator
  # Template uses Antigen
  antigenSetup

  separator
  # Zsh installation
  zshrcTemplate
fi

if [[ $INSTALL_NVM ]]; then
  separator
  nvmSetup
fi

if [[ $INSTALL_CODE_FROM_GIT ]]; then
  separator
  cloneFromGithub
fi

if [[ $INSTALL_TRIM_RUBY_ENV ]]; then
  separator
  setupRuby
fi

if [[ $INSTALL_ZSHRC_ANTIGEN ]]; then
  separator
  antigenSetup
fi

if [[ $INSTALL_FZF ]]; then
  separator
  fzfSetup
fi

if [[ $FAIL_FAST ]]; then
# If set, the return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully. This option is disabled by default.
  set -o pipefail
  IFS=$'\n\t'
fi

if [[ $EXPRESS_INSTALL ]]; then
  echo "\nExpress installation"
  clitools
  homebrew
  antigenSetup
  zshrcTemplate
  nvmSetup
  cloneFromGithub
  setupRuby
  antigenSetup
  fzfSetup
fi
