#!/bin/echo Run: source

export ONE_PASSWORD_ITEM=cloud.dpmsupport
name=$(basename $0); name=$name:r:s/env.//

export SDC_VERSION=${SDC_VERSION:-5.10.0}
source _env.cloud.3x.zsh $name