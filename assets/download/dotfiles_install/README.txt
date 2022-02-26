## README ##

-> setup.sh and utils.sh are used to setup the dotfiles from the tar.gz

Generate/Export git repo from "dev" branch:
----------------------------------------------
git archive --format=tar --prefix="srihas_dev_dotfiles/" dev | gzip -n > "/home/esliarp/work/http/dotfiles/srihas_dev_dotfiles.tar.gz"

Note: Run the above cmd from the git cloned directory to export git repo as archive from "dev" branch in the location specified above

The dotfiles directory contains the files: setup.sh, utils.sh and srihas_dev_dotfiles.tar.gz
Hosting this directory as http webserver end point would help to download and execute setup.sh using the below commands:

Commands to setup:
--------------------
bash -c "$(wget -qO - http://srihas.github.io/assets/download/dotfiles_install/setup.sh)"

