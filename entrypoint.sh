#!/bin/bash

# Wait until Consul can be contacted
until curl -s ${CONSUL_HTTP_ADDR}/v1/status/leader | grep 8300; do
  echo "Waiting for Consul to start"
  sleep 1
done

# If we do not need to register a service just run the command
if [ ! -z "$SERVICE_CONFIG" ]; then
  # register the service with consul
  echo "Registering service with consul $SERVICE_CONFIG"
  cat "${SERVICE_CONFIG}" | \
    jq --arg addr "$(ip addr show eth0 | awk '$1 == "inet" { print $2 }' | cut -d/ -f1)"  \
      '.[1].service.port as $port | .[1].service.checks[0].TCP |= "\($addr):\($port)" | .[0].service.address |= $addr' \
    > "/tmp/service.json"
  cat /tmp/service.json | jq '.[0]' > /tmp/service-0.json
  cat /tmp/service.json | jq '.[1]' > /tmp/service-1.json

  set -x

  cat /tmp/service-0.json
  consul services register /tmp/service-0.json

  cat /tmp/service-1.json
  consul services register /tmp/service-1.json
  
  exit_status=$?
  if [ $exit_status -ne 0 ]; then
    echo "### Error writing service config: $file ###"
    cat $file
    echo ""
    exit 1
  fi
fi

# register any central config from individual files
if [ ! -z "$CENTRAL_CONFIG" ]; then
  IFS=';' read -r -a configs <<< ${CENTRAL_CONFIG}

  for file in "${configs[@]}"; do
    echo "Writing central config $file"
    consul config write $file
     
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
      echo "### Error writing central config: $file ###"
      cat $file
      echo ""
      exit 1
    fi
  done
fi

# register any central config from a folder
if [ ! -z "$CENTRAL_CONFIG_DIR" ]; then
  for file in `ls -v $CENTRAL_CONFIG_DIR/*`; do 
    echo "Writing central config $file"
    consul config write $file
    echo ""

    exit_status=$?
    if [ $exit_status -ne 0 ]; then
      echo "### Error writing central config: $file ###"
      cat $file
      echo ""
      exit 1
    fi
  done
fi

# Run the command if specified
if [ "$#" -ne 0 ]; then
  echo "Running command: $@"
  exec "$@" &

  # Block using tail so the trap will fire
  tail -f /dev/null &
  PID=$!
  wait $PID
fi
