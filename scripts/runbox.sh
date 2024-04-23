#! /bin/sh
set -e
VERSION=${IBAVERSION:-latest}
CONTAINER=${IBACONTAINER:-infrastructurebuilder/ansible-container}:${VERSION}
AWSCFG=${HOME}/.aws
if [ -f ${PWD}/.envrc ]; then
  # Use this one
  ENVMNT="-v \"${PWD}/.envrc\":/root/.envrc:ro"
else 
  if [ -f ${HOME}/.envrc ]; then
    ENVMNT="-v \"${HOME}/.envrc\":/root/.envrc:ro"
  else
    unset ENVMNT
  fi
fi
if [ -d ${PWD}/.aws ]; then
  # Use this one
  AWSMNT="-v \"${PWD}\":/root/.aws:ro"
else 
  if [ -d ${HOME}/.aws ]; then
    AWSMNT="-v \"${HOME}/.aws\":/root/.aws:ro"
  else
    unset AWSVMNT
  fi
fi
if [ "${NOWAWSMOUNT}" -eq "true" ]; then
  unset AWSMNT
fi
CMD="docker run --cap-add SYS_ADMIN --device /dev/fuse -it ${ENVMNT} ${AWSMNT} ${CONTAINER} $@ "
echo Running ${CMD}
eval "${CMD}"
