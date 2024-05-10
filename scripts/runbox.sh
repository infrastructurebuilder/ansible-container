#! /bin/sh
set -e
VERSION=${IBAVERSION:-latest}
CONTAINER=${IBACONTAINER:-infrastructurebuilder/ansible-container}:${VERSION}
AWSCFG=${HOME}/.aws
IBVOLUME=${IBVOLUME:-"${USER}-vol"}
if [ "X${NOIBVOLMOUNT}" = "Xtrue" ]; then
  unset IBVOLUME
fi
if [ "X${IBVOLUME}" != "X" ]; then
  if [ $(docker volume inspect ${IBVOLUME} 2>/dev/null | jq -r '.[0].Name') != "${IBVOLUME}" ]; then
    echo "Creating volume ${IBVOLUME}"
    docker volume create ${IBVOLUME}
  fi
  IBVOLUMEMNT="-v ${IBVOLUME}:/root"
else
  unset IBVOLUMEMNT
fi
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
if [ "X${NOENVMOUNT}" = "Xtrue" ]; then
  unset ENVMNT
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
if [ "X${NOAWSMOUNT}" = "Xtrue" ]; then
  unset AWSMNT
fi
CMD="docker run --cap-add SYS_ADMIN --device /dev/fuse -it ${IBVOLUMEMNT} ${ENVMNT} ${AWSMNT} -v \"$(pwd)\":/work ${CONTAINER} $@ "
echo Running ${CMD}
eval "${CMD}"
