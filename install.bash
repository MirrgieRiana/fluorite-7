#!/usr/bin/env bash

if [ -d fluorite-7 ]
then
  (
    cd fluorite-7
    git checkout -f
    git clean -fd
    git pull
  )
else
  GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no' git clone --depth=1 https://github.com/MirrgieRiana/fluorite-7.git
fi

echo -e '#!/usr/bin/env bash\nexec "$(dirname "$0")"/fluorite-7/fl7 "$@"' > fl7
echo -e '#!/usr/bin/env bash\nexec "$(dirname "$0")"/fluorite-7/fl7m "$@"' > fl7m
cp fluorite-7/fl7u fl7u
echo -e '#!/usr/bin/env bash\nexec "$(dirname "$0")"/fluorite-7/fluorite7 "$@"' > fluorite7
chmod a+x fl7
chmod a+x fl7m
chmod a+x fl7u
chmod a+x fluorite7
chmod a+x fluorite-7/fl7
chmod a+x fluorite-7/fl7m
chmod a+x fluorite-7/fluorite7

(
  cd fluorite-7
  rm -rf node_modules
  npm install
  ./compile.bash
  ./fl7m pull 'https://raw.githubusercontent.com/MirrgieRiana/fl7-module_fl7.argv/main/module.json?'
)
