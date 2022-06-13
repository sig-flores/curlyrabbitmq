#!/usr/bin/env bash

# ALL_CLUSTERS=true to allow looking up in staging, DR, EDA, etc

if [[ -n "${IS_DEV_POLARIS_CONTROL}" && "${IS_DEV_POLARIS_CONTROL}" == "true" ]]; then
  export POLARIS_CONTROL_URL="https://polariscontrol.polaris-cc-staging.sig-clops.synopsys.com"
else
  export POLARIS_CONTROL_URL="https://polariscontrol.cloudops.synopsys.com"
fi


if [[ "${ENVIRONMENT_NAME}" == "" && "${CUSTOMER_DNS}" == "" ]]; then
  echo "Must set ENVIRONMENT_NAME or CUSTOMER_DNS to look up the environment."
  exit 1
fi

IFS=$'\n'

if [[ "${ENVIRONMENT_NAME}" != "" ]]; then

  ENVIRONMENT_JSON="$(curl --fail --silent \
      -H "X-API-KEY: ${POLARIS_CONTROL_API_KEY}" \
      -H "Accept: application/json" \
      "${POLARIS_CONTROL_URL}/api/environment/${ENVIRONMENT_NAME}")"
  RETCODE=$?

  if [[ $RETCODE -ne 0 || "${CURL_RESULT}" != "" ]]; then
    echo "Unknown curl output when trying to list environments:"
    echo ${RETCODE}
    exit 1
  fi

  POLARIS_HOSTNAME="$(echo "${ENVIRONMENT_JSON}" | jq -r '.url')"
  CLUSTER_NAME="$(echo "${ENVIRONMENT_JSON}" | jq -r '.cluster.name')"

  if [[ "${CLUSTER_NAME}" == "" || "${CLUSTER_NAME}" == "null" ]]; then
    echo "Environment not found"
    exit 1
  fi

  CLUSTER_JSON="$(curl --fail --silent \
      -H "X-API-KEY: ${POLARIS_CONTROL_API_KEY}" \
      -H "Accept: application/json" \
      "${POLARIS_CONTROL_URL}/api/cluster/${CLUSTER_NAME}")"
  RETCODE=$?

  if [[ $RETCODE -ne 0 || "${CURL_RESULT}" != "" ]]; then
    echo "Unknown curl output when trying to get cluster:"
    echo ${RETCODE}
    exit 1
  fi

  CLUSTER_REGION="$(echo "${CLUSTER_JSON}" | jq -r '.google_region')"
  GCP_PROJECT="$(echo "${CLUSTER_JSON}" | jq -r '.google_project')"

  jq -n -c --arg ENV_NAME "${ENVIRONMENT_NAME}" --arg URL "${POLARIS_HOSTNAME}" --arg CLUSTER "${CLUSTER_NAME}" --arg REGION "${CLUSTER_REGION}"  --arg PROJECT "${GCP_PROJECT}" '{"name": $ENV_NAME, "url": $URL, "cluster": $CLUSTER, "region": $REGION, "project": $PROJECT }'

else

  ENVIRONMENT_JSON_LIST="$(curl --fail --silent \
      -H "X-API-KEY: ${POLARIS_CONTROL_API_KEY}" \
      -H "Accept: application/json" \
      "${POLARIS_CONTROL_URL}/api/environment/")"
  RETCODE=$?

  if [[ $RETCODE -ne 0 || "${CURL_RESULT}" != "" ]]; then
    echo "Unknown curl output when trying to list environments:"
    echo ${RETCODE}
    exit 1
  fi

  IFS=$'\n'

  ENV_IDX=0
  while [[ "${ENV_IDX}" -lt 99999 ]]; do

    ENV_NAMESPACE="$(echo "${ENVIRONMENT_JSON_LIST}" | jq -r '.['"${ENV_IDX}"'].name')"
    POLARIS_HOSTNAME="$(echo "${ENVIRONMENT_JSON_LIST}" | jq -r '.['"${ENV_IDX}"'].url')"
    CLUSTER_NAME="$(echo "${ENVIRONMENT_JSON_LIST}" | jq -r '.['"${ENV_IDX}"'].cluster.name')"

    if [[ "${ENV_NAMESPACE}" == "null" ]]; then
      break
    fi

    if [[ "${POLARIS_HOSTNAME}" != "${CUSTOMER_DNS}" ]]; then
      let ENV_IDX=ENV_IDX+1
      continue
    fi

    if [[ "${ALL_CLUSTERS}" == "" ]]; then
      # Hide some clusters
      if [[ "${CLUSTER_NAME}" == "stg-mt-cluster-01" || "${CLUSTER_NAME}" == "dr-cluster-01" || "${CLUSTER_NAME}" == "dreu-cluster-01" || "${CLUSTER_NAME}" == "polaris-eda00" || "${CLUSTER_NAME}" == "poc-cluster-01" || "${CLUSTER_NAME}" == "prodpoc-cluster-02" ]]; then
        let ENV_IDX=ENV_IDX+1
        continue
      fi
    fi

    CLUSTER_JSON="$(curl --fail --silent \
        -H "X-API-KEY: ${POLARIS_CONTROL_API_KEY}" \
        -H "Accept: application/json" \
        "${POLARIS_CONTROL_URL}/api/cluster/${CLUSTER_NAME}")"
    RETCODE=$?

    if [[ $RETCODE -ne 0 || "${CURL_RESULT}" != "" ]]; then
      echo "Unknown curl output when trying to get cluster:"
      echo ${RETCODE}
      exit 1
    fi

    CLUSTER_REGION="$(echo "${CLUSTER_JSON}" | jq -r '.google_region')"
    GCP_PROJECT="$(echo "${CLUSTER_JSON}" | jq -r '.google_project')"

    jq -n -c --arg ENV_NAME "${ENV_NAMESPACE}" --arg URL "${POLARIS_HOSTNAME}" --arg CLUSTER "${CLUSTER_NAME}" --arg REGION "${CLUSTER_REGION}"  --arg PROJECT "${GCP_PROJECT}" '{"name": $ENV_NAME, "url": $URL, "cluster": $CLUSTER, "region": $REGION, "project": $PROJECT }'

    break

  done # For each namespace


fi
