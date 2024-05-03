FROM fedora:40
#FROM rockylinux:8.9
ENV HOME "/root"
ENV TFVERSION "1.8.1"

# # See https://github.com/kahing/goofys/releases for goofys versions or just use "latest"
# # ENV GOOFYSVERSION "v0.24.0"
# ENV GOOFYSVERSION "latest"

## For the following versions, if you specify an actual
## version, the version will be installed.  However, you
## must precede the version with a hyphen.  For example,
## "-1.6.2-1" will install version 1.6.2-1.  If you do not
## specify a version, the latest version will be installed.

ENV OPENTOFUVERSION ""
# ENV OPENTOFUVERSION "-1.6.2-1"
ENV PACKERVERSION "" 
# ENV PACKERVERSION "-1.10.3-1" 
ENV S3FUSEVERSION ""
#ENV S3FUSEVERSION "-1.94"
# --
ENV PATH "${HOME}/.local/bin:${HOME}/.tfenv/bin:${HOME}/.awscliv2/binaries:${PATH}"
VOLUME /root
COPY files/DOTenvrc /root/.envrc
COPY files/opentofu.repo /etc/yum.repos.d/opentofu.repo
# Primary software installation
RUN <<PKGS
  mkdir -p ${HOME}/.local/bin/
  groupadd -g 1020 rvm
  dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && dnf -y update && dnf groupupdate -y core
  # dnf -y install epel-release && dnf -y update    # RHEL/Rocky only 
  # dnf -y install git python39-devel which unzip findutils environment-modules dnf-plugins-core
  dnf -y install sudo git python-devel which unzip findutils environment-modules dnf-plugins-core wget direnv
  # dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
  wget -O- https://rpm.releases.hashicorp.com/fedora/hashicorp.repo | sed -e s/\$releasever/39/ | sudo tee /etc/yum.repos.d/hashicorp.repo
  # dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
  # dnf -y install  sudo patch autoconf automake bison bzip2 gcc-c++ libffi-devel libtool make patch sqlite-devel zlib-devel libffi-devel readline-devel openssl-devel glibc-headers glibc-devel
  #   dnf module reset ruby -y
  #   dnf -y install @ruby:3.1

  # Repo installed with `epel-release`
  # rubygems installs ruby 3.3.0 and bundler
  
  dnf -y install direnv rubygems s3fs-fuse${S3FUSEVERSION} packer${PACKERVERSION} tofu${OPENTOFUVERSION} 

  # curl -sfL https://direnv.net/install.sh | bash
  # echo "eval \"\$(direnv hook bash)\"" >> ${HOME}/.bashrc
  direnv allow /root
  echo "alias ll='ls -l'" >> ${HOME}/.bashrc
  echo "alias python='python3'" >> ${HOME}/.bashrc
  echo "alias pip='pip3'" >> ${HOME}/.bashrc
  # Pipx can be installed via package in fedora
  # dnf -y install pipx poetry ansible
  python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
  # Remove the packer that comes with the base image in Cracklib.  It is just a symlink
  rm -f /usr/sbin/packer 
  # Install tfenv
  git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv && tfenv use ${TFVERSION}
  # curl https://github.com/kahing/goofys/releases/${GOOFYSVERSION}/download/goofys -o ${HOME}/.local/bin/goofys
  # chmod +x ${HOME}/.local/bin/goofys
PKGS
RUN <<FSTAB
cat <<FSTABFILE >> /etc/fstab
# Example of goofys mount (not currently installed)
# goofys#bucket:prefix   /mnt/mountpoint        fuse     _netdev,allow_other,--file-mode=0444,--dir-mode=0777    0  0
 \# Example of s3fs mount
 \#s3fs#bucket:prefix   /mnt/mountpoint        fuse     _netdev,allow_other,profile=awsprofilename,--file-mode=0444,--dir-mode=0777    0  0
FSTABFILE
# Install opentofu (Original script is commented out below)
  # curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh \
  #    && chmod +x /tmp/install-opentofu.sh \
  #    && /tmp/install-opentofu.sh --install-method rpm \
  #    && rm /tmp/install-opentofu.sh
echo "eval \"\$(direnv hook bash)\"" >> ${HOME}/.bashrc

FSTAB
RUN <<PIPXS
  # Install poetry
  pipx install poetry
  # Install ansible
  pipx install --include-deps ansible
  # Install awscliv2 
  # (this does look a little weird, but it is correct)
  pipx install awscliv2 && awscliv2 --install && pipx uninstall awscliv2
PIPXS
# RUN <<RUBY1
#   # RVM installed above for fedora
#   # Key for RVM
#   # command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
#   # command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
#   # #  gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
#   #   # Install Ruby and RVM
#   # echo "export rvm_max_time_flag=20" >> ~/.rvmrc
#   # dnf -y install ruby
#   # curl -sSL https://get.rvm.io | bash -s stable
#   # echo "source /etc/profile.d/rvm.sh" >> ${HOME}/.bashrc
#   # useradd root rvm  # usermod -aG rvm root
#   # source /etc/profile.d/rvm.sh
# RUBY1
# RUN <<RUBY2
#   # rvm install 3.3.1
#   # rvm use 3.3.1 --default
#   # gem install bundler
# RUBY2
RUN <<RUBY3
  gem install --no-document bundler fpm
RUBY3
RUN <<ASDF
  # dnf install -y curl git
  # git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
  # echo '. "$HOME/.asdf/asdf.sh"' >> ${HOME}/.bashrc
  # echo '. "$HOME/.asdf/completions/asdf.bash"' >> ${HOME}/.bashrc  
ASDF
WORKDIR /root
RUN <<DIRENV
  mkdir -p ${HOME}/.config/direnv
  cat <<DIRENVFILE >> $HOME/.config/direnv/direnv.toml
  #
  [whitelist]
  exact = ["/root/.envrc"]
  prefix = [ "/work" ]
DIRENVFILE
DIRENV
CMD ["/bin/bash"]