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
echo -e '#!/usr/bin/env bash\nexec "$(dirname "$0")"/fluorite-7/fluorite7 "$@"' > fluorite7
chmod +x fl7
chmod +x fluorite7
chmod +x fluorite-7/fl7
chmod +x fluorite-7/fluorite7
(
  cd fluorite-7
  npm install
  ./compile.bash
)
