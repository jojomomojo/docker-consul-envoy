#!/bin/bash

# Wait until Consul can be contacted
until curl -s ${CONSUL_HTTP_ADDR}/v1/status/leader | grep 8300; do
  echo "Waiting for Consul to start"
  sleep 1
done

while true; do 
  # If we do not need to register a service just run the command
  if [ ! -z "$SERVICE_CONFIG" ]; then
    # register the service with consul
    echo "Registering service with consul $SERVICE_CONFIG"
    IP="$(ip addr show eth0 | awk '$1 == "inet" { print $2 }' | cut -d/ -f1)"
    cat "${SERVICE_CONFIG}" | sed "s#YYYY#${IP}#g" > /tmp/service.hcl
    consul services register /tmp/service.hcl
    
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
      echo "### Error writing service config: /tmp/service.hcl ###"
      cat /tmp/service.hcl
      echo ""
      exit 1
    fi
  fi

  if [ ! -z "$SERVICE_PROXY_CONFIG" ]; then
    # register the service with consul
    echo "Registering service with consul $SERVICE_PROXY_CONFIG"
    IP="$(ip addr show eth0 | awk '$1 == "inet" { print $2 }' | cut -d/ -f1)"
    cat "${SERVICE_PROXY_CONFIG}" | sed "s#YYYY#${IP}#g" > /tmp/service-proxy.hcl
    consul services register /tmp/service-proxy.hcl
    
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
      echo "### Error writing service config: /tmp/service-proxy.hcl ###"
      cat /tmp/service-proxy.hcl
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
    "$@"
  fi
done
