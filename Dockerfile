#FROM fedora:41
FROM rockylinux:8.9
ENV HOME "/root"
ENV TFVERSION "1.8.1"
# Comment out or remove value from OPENTOFUVERSION this for "latest" 
ENV OPENTOFUVERSION ""
# ENV OPENTOFUVERSION "-1.6.2-1"
# Comment out or remove value from PACKERVERSION this for "latest" 
ENV PACKERVERSION "" 
# ENV PACKERVERSION "-1.10.3-1" 
# See https://github.com/kahing/goofys/releases for goofys versions or just use "latest"
# ENV GOOFYSVERSION "v0.24.0"
ENV GOOFYSVERSION "latest"
ENV PATH "${HOME}/.local/bin:${HOME}/.tfenv/bin:${HOME}/.awscliv2/binaries:${PATH}"
COPY files/DOTenvrc /root/.envrc
COPY files/opentofu.repo /etc/yum.repos.d/opentofu.repo
# Primary software installation
RUN <<PKGS
  dnf -y update
  dnf -y install git python39-devel which unzip findutils environment-modules dnf-plugins-core sudo epel-release
  # Repo installed with `epel-release`
  dnf -y install s3fs-fuse

  dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
  curl -sfL https://direnv.net/install.sh | bash
  echo "eval \"\$(direnv hook bash)\"" >> ${HOME}/.bashrc
  echo "alias ll='ls -l'" >> ${HOME}/.bashrc
  echo "alias python='python3'" >> ${HOME}/.bashrc
  python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
  # Remove the packer that comes with the base image in Cracklib.  It is just a symlink
  rm -f /usr/sbin/packer 
  # Install hashicorp packer
  dnf -y install packer${PACKERVERSION}
  # Install tfenv
  git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv && tfenv use ${TFVERSION}
  curl https://github.com/kahing/goofys/releases/${GOOFYSVERSION}/download/goofys -o ${HOME}/.local/bin/goofys
  chmod +x ${HOME}/.local/bin/goofys
  echo <<FSTAB
  # Example of goofys mount
  # goofys#bucket:prefix   /mnt/mountpoint        fuse     _netdev,allow_other,--file-mode=0444,--dir-mode=0777    0  0
  # Example of s3fs mount
  # s3fs#bucket:prefix   /mnt/mountpoint        fuse     _netdev,allow_other,profile=awsprofilename,--file-mode=0444,--dir-mode=0777    0  0
  FSTAB >> /etc/fstab
  # Install opentofu (Original script is commented out below)
  dnf -y install tofu${OPENTOFUVERSION}
  # curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh \
  #    && chmod +x /tmp/install-opentofu.sh \
  #    && /tmp/install-opentofu.sh --install-method rpm \
  #    && rm /tmp/install-opentofu.sh
PKGS
RUN <<PIPXS
  # Install poetry
  pipx install poetry
  # Install ansible
  pipx install --include-deps ansible
  # Install awscliv2
  pipx install awscliv2 && awscliv2 --install && pipx uninstall awscliv2
PIPXS
RUN direnv allow /root
WORKDIR /root
CMD ["/bin/bash"]