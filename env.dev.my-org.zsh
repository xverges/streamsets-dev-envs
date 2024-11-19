#!/bin/echo Run: source

export ONE_PASSWORD_ITEM=platform.dev.my-org
name=$(basename $0); name=$name:r:s/env.//

export SDC_VERSION=${SDC_VERSION:-5.11.0}
source _env.platform.zsh $name