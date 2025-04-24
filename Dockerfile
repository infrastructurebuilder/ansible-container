FROM fedora:42
#FROM rockylinux:8.9
ENV HOME="/root"
ENV TFVERSION="1.8.1"

# # See https://github.com/kahing/goofys/releases for goofys versions or just use "latest"
# # ENV GOOFYSVERSION "v0.24.0"
# ENV GOOFYSVERSION "latest"

## For the following versions, if you specify an actual
## version, the version will be installed.  However, you
## must precede the version with a hyphen.  For example,
## "-1.6.2-1" will install version 1.6.2-1.  If you do not
## specify a version, the latest version will be installed.

ENV OPENTOFUVERSION=""
# ENV OPENTOFUVERSION "-1.6.2-1"
ENV PACKERVERSION="" 
# ENV PACKERVERSION "-1.10.3-1" 
ENV S3FUSEVERSION=""
#ENV S3FUSEVERSION "-1.94"
# --
ENV PATH="${HOME}/.local/bin:${HOME}/.tfenv/bin:${HOME}/.awscliv2/binaries:${PATH}"
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
  dnf -y install sudo awk git python-devel which unzip findutils environment-modules dnf-plugins-core wget direnv
  # dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
  # See https://www.hashicorp.com/en/blog/announcing-the-hashicorp-linux-repository
  release=fedora && wget -O- https://rpm.releases.hashicorp.com/$release/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo
  # dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
  # dnf -y install  sudo patch autoconf automake bison bzip2 gcc-c++ libffi-devel libtool make patch sqlite-devel zlib-devel libffi-devel readline-devel openssl-devel glibc-headers glibc-devel
  #   dnf module reset ruby -y
  #   dnf -y install @ruby:3.1
  dnf -y install rubygems 
  dnf -y install uv
PKGS
RUN <<PKGS2

  # Repo installed with `epel-release`
  # rubygems installs ruby 3.3.0 and bundler
  
  dnf -y install direnv s3fs-fuse${S3FUSEVERSION} packer${PACKERVERSION} tofu${OPENTOFUVERSION}

  echo "eval \"\$(direnv hook bash)\"" >> ${HOME}/.bashrc
  direnv allow /root
  echo "alias ll='ls -l'" >> ${HOME}/.bashrc
  echo "alias python='python3'" >> ${HOME}/.bashrc
  echo "alias pip='pip3'" >> ${HOME}/.bashrc
  # Pipx can be installed via package in fedora
  python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
  # Remove the packer that comes with the base image in Cracklib.  It is just a symlink
  rm -f /usr/sbin/packer 
  # Install tfenv
  git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv && tfenv use ${TFVERSION}
  # curl https://github.com/kahing/goofys/releases/${GOOFYSVERSION}/download/goofys -o ${HOME}/.local/bin/goofys
  # chmod +x ${HOME}/.local/bin/goofys
  cat <<FSTABFILE >> /etc/fstab
  \# Example of s3fs mount
  \#s3fs#bucket:prefix   /mnt/mountpoint        fuse     _netdev,allow_other,profile=awsprofilename,--file-mode=0444,--dir-mode=0777    0  0
FSTABFILE
  gem install --no-document bundler fpm
  mkdir -p ${HOME}/.config/direnv
  cat <<DIRENVFILE >> $HOME/.config/direnv/direnv.toml
#
[whitelist]
exact = ["/root/.envrc"]
prefix = [ "/work" ]
DIRENVFILE
PKGS2
RUN <<PIPXS
  # Install poetry
  pipx install poetry
  # Install ansible
  pipx install --include-deps ansible
  # Install awscliv2  (this does look a little weird, but it is correct)
  pipx install awscliv2 && awscliv2 --install && pipx uninstall awscliv2
PIPXS
WORKDIR /root
CMD ["/bin/bash"]