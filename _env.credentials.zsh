#!/bin/echo Run: source

function get_from_1pass(){

if [ -z "$ONE_PASSWORD_ITEM" ]; then
  export ONE_PASSWORD_ITEM=local.platform
  echo "Default value will be used as ONE_PASSWORD_ITEM=$ONE_PASSWORD_ITEM"  
fi

# Declare an associative array
declare -A field_map

while IFS=: read -r key value; do
  # Trim whitespace from the key and value
  key=$(echo $key | xargs)
  value=$(echo $value | xargs)
  
  # Skip adding if the value is empty
  if [[ -z "$value" ]]; then
    value="NOT_SET"
  fi

  field_map[$key]=$value
done <<< $(op item get $ONE_PASSWORD_ITEM --format json | jq -r '.fields[] | "\(.label): \(.value)"')

#For debug purpose
#for key val in "${(@kv)field_map}"; do
#    echo "$key -> $val"
#done


# Auth ####

export ASTER_EMAIL=${field_map[username]}
export ASTER_EMAIL_PWD=${field_map[password]}
export ASTER_LOGIN_URL=${field_map[website]}
export CRED_ID=${field_map[CRED_ID]}
export CRED_TOKEN=${field_map[CRED_TOKEN]}
export ASTER_URL=${ASTER_LOGIN_URL}
export ASTER_USER_EMAIL=${ASTER_EMAIL}
export ASTER_USER_PASSWORD=${ASTER_EMAIL_PWD}

if FIREBASE_API_KEY=$(op read "op://Employee/$ONE_PASSWORD_ITEM/firebase-api-key"); then
  export FIREBASE_API_KEY
elif FIREBASE_API_KEY=$(op read "op://Cloud Development/Firebase/LOCAL/Api key"); then
  echo "Using FIREBASE_API_KEY from op://Cloud Development/Firebase/LOCAL/Api key"
  export FIREBASE_API_KEY
else
  echo "FIREBASE_API_KEY not fond neither in"
  echo "op://Employee/$ONE_PASSWORD_ITEM/firebase-api-key"
  echo "nor"
  echo "op://Cloud Development/Firebase/LOCAL/Api key"
  echo "Please set FIREBASE_API_KEY"
  return 1
fi
}

function set_cred_from_aster_dev(){
  source $HOME/src/streamsets/aster-security/dev/.stf-env.sh
  #echo $CRED_ID
  #echo $CRED_TOKEN
  op item edit $ONE_PASSWORD_ITEM "CRED_ID=$CRED_ID" > /dev/null || return 1
  echo "CRED_ID updated"
  op item edit $ONE_PASSWORD_ITEM "CRED_TOKEN=$CRED_TOKEN" > /dev/null || return 1
  echo "CRED_TOKEN updated"
}