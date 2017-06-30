# Usage examples:
  # refresh_3scale_resources.sh --threescale_tenant_name 3scale --OCP_WILDCARD_DOMAIN $OCP_WILDCARD_DOMAIN --ON_PREM_ACCESS_TOKEN x7fwv5s26cs7ymqr


mkdir -p $API_RESPONSE_DIR

function check_variables() {
  if [ "x$threescale_tenant_name" == "x"  ]; then
    echo "Please ensure the following environment variable is set: threescale_tenant_name"; exit 1;
  fi
  if [ "x$ON_PREM_ACCESS_TOKEN" == "x"  ]; then
    echo "Please ensure the following environment variable is set: ON_PREM_ACCESS_TOKEN"; exit 1;
  fi
  if [ "x$OCP_WILDCARD_DOMAIN" == "x"  ]; then
    echo "Please ensure the following environment variable is set: OCP_WILDCARD_DOMAIN"; exit 1;
  fi
  if [ "x$vertx_prod_route" == "x"  ]; then
    echo "Please ensure the following environment variable is set: vertx_prod_route"; exit 1;
  fi

  echo -en "threescale_tenant_name = $threescale_tenant_name : ON_PREM_ACCESS_TOKEN = $ON_PREM_ACCESS_TOKEN : OCP_WILDCARD_DOMAIN = $OCP_WILDCARD_DOMAIN : vertx_prod_route = $vertx_prod_route\n\n" > $LOG_FILE
}

function list_services() {
  curl -f -v -k -X GET "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/services.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/existing_services.xml

  if [ $? -ne 0 ]; then
    echo "*** ERROR in list_services()"; exit 1
  fi
  echo -en "\nlist_services() Listed existing services in: $API_RESPONSE_DIR/existing_services.xml\n" >> $LOG_FILE

}

function vertx_service() {

  # Delete existing vertx_service
  eval vertx_serviceId=\"`xmlstarlet sel -t -m '//service[name = "vertx_service"]' -v 'id' -n $API_RESPONSE_DIR/existing_services.xml`\"
  if [ "x$vertx_serviceId" != "x" ]; then
    echo -en "\nvertx_service() will now delete service with Id = $vertx_serviceId" >> $LOG_FILE

    curl f -v -k -X DELETE "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/services/$vertx_serviceId.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       -d "system_name=vertx_service" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_service_delete_response.xml
    OUT=$?

    # curl returns a status code of 2 after having deleted a service; not sure why
    if [ $OUT -ne 2 ]; then
      echo "*** ERROR in deleting existing vertx service() $OUT"; exit 1
    fi

    # Appears that occasionally 3Scale will fail with the following exception after immediately attempting to re-create a service after having just deleted one with the same name:  422 Unprocessable Entity
    # Subsequently, let's now sleep for a few seconds 
    sleep 5;

  fi

  # Create vertx_service
  echo -en "\nvertx_service() will now create vertx_service " >> $LOG_FILE
  curl -f -v -k -X POST "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/services.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       -d "name=vertx_service" \
       -d "system_name=vertx_service" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_service_response.xml
  if [ $? -ne 0 ]; then
    echo "*** ERROR in create vertx service()"; exit 1
  fi

  eval vertx_serviceId=\"`xmlstarlet sel -t -m '//service' -v 'id' -n $API_RESPONSE_DIR/vertx_service_response.xml`\"
  echo -en "\nvertx_service() vertx_service create with Id = $vertx_serviceId" >> $LOG_FILE


  # Review the hits metric associated with the vertx_service
  eval vertx_hit_metric_id=\"`xmlstarlet sel -t -m '//service/metrics/metric[name = "hits"]' -v 'id' -n $API_RESPONSE_DIR/vertx_service_response.xml`\"
  echo -en "\nvertx_service() vertx_hit_metric_id = $vertx_hit_metric_id" >> $LOG_FILE

  # Review the Default Service Plan
  curl -f -v -k -X GET "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/services/$vertx_serviceId/service_plans.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_default_service_plan.xml
  if [ $? -ne 0 ]; then
    echo "*** ERROR in reviewing default service plan"; exit 1
  fi

  eval vertx_servicePlanId=\"`xmlstarlet sel -t -m '//plan' -v 'id' -n $API_RESPONSE_DIR/vertx_default_service_plan.xml`\"
  echo -en "\nvertx_service() vertx_servicePlanId = $vertx_servicePlanId" >> $LOG_FILE
}


function custom_plans() {

  echo -en "\n\ncustom_plans() creating 3scale custom plans for vertx_service" >> $LOG_FILE

  curl -f -v -k -X POST "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/services/$vertx_serviceId/application_plans.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       -d "name=vertx_app_plan" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_app_plan_response.xml
  if [ $? -ne 0 ]; then
    echo "*** ERROR in creating custom app plan"; exit 1
  fi

  eval vertx_appPlanId=\"`xmlstarlet sel -t -m '//plan' -v 'id' -n $API_RESPONSE_DIR/vertx_app_plan_response.xml`\"

  export vertx_hit_metric_limit_value=100
  curl -f -v -k -X POST "https://$threescale_tenant_name-admin.${OCP_WILDCARD_DOMAIN}/admin/api/application_plans/$vertx_appPlanId/metrics/$vertx_hit_metric_id/limits.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       -d "application_plan_id=$vertx_appPlanId" \
       -d "period=minute" \
       -d "value=$vertx_hit_metric_limit_value" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_hit_metric_limit_response.xml
  if [ $? -ne 0 ]; then
    echo "*** ERROR in updating vertx_hit_metric_limit"; exit 1
  fi

  eval vertx_hit_metric_limitId=\"`xmlstarlet sel -t -m '//limit' -v 'id' -n $API_RESPONSE_DIR/vertx_hit_metric_limit_response.xml`\"

  curl -v -k -X POST "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/account_plans.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       -d "name=vertx_account_plan" \
       -d "system_name=vertx_account_plan" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_account_plan_response.xml
  if [ $? -ne 0 ]; then
    echo "*** ERROR in creating vertx account plan"; exit 1
  fi

  eval vertx_accountPlanId=\"`xmlstarlet sel -t -m '//plan' -v 'id' -n $API_RESPONSE_DIR/vertx_account_plan_response.xml`\"

}

function account() {


  echo -en "\n\naccount() creating account and user " >> $LOG_FILE

  # Determine if there is an exsiting vertx_account
  curl -f -v -k -X GET "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/accounts.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/accounts_list.xml
  eval vertx_accountId=\"`xmlstarlet sel -t -m '//account[org_name = "vertx_account"]' -v 'id' -n $API_RESPONSE_DIR/accounts_list.xml`\"

  # Delete existing vertx_account 
  if [ "x$vertx_accountId" != "x" ]; then
    echo -en "\naccount() will now delete account with Id = $vertx_accountId" >> $LOG_FILE

    curl f -v -k -X DELETE "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/accounts/$vertx_accountId.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_service_delete_response.xml
    OUT=$?
    # curl returns a status code of 2 after having deleted an account; not sure why
    if [ $OUT -ne 2 ]; then
      echo "*** ERROR in deleting existing vertx_account() $OUT"; exit 1
    fi
  fi

  export vertx_dev_email=jbride@redhat.com
  export pleaseHackMePasswd=password
  curl -v -k -X POST "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/signup.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       -d "org_name=vertx_account" \
       -d "username=vertx_dev" \
       -d "email=$vertx_dev_email" \
       -d "password=$pleaseHackMePasswd" \
       -d "account_plan_id=$vertx_accountPlanId" \
       -d "service_plan_id=$vertx_servicePlanId" \
       -d "application_plan_id=$vertx_appPlanId" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_account_response.xml

  eval vertx_accountId=\"`xmlstarlet sel -t -m '//account' -v 'id' -n $API_RESPONSE_DIR/vertx_account_response.xml`\"

  eval vertx_app_user_key=\"`xmlstarlet sel -t -m '//account/applications/application[service_id = "'$vertx_serviceId'"]' -v 'user_key' -n $API_RESPONSE_DIR/vertx_account_response.xml`\"
  echo -en "\n\naccount() vertx_app_user_key determined to be: $vertx_app_user_key" >> $LOG_FILE

}

function serviceProxy() {
  echo -en "\n\nserviceProxy() update service proxy " >> $LOG_FILE

  eval vertx_service_ip=\"`oc get service vertx-greeting-service -n bservices --template "{{.spec.clusterIP}}"`\"
  if [ $? -ne 0 ]; then
    echo "*** ERROR getting vertx_service_ip"; exit 1
  fi

  curl -v -k -X PATCH "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/services/$vertx_serviceId/proxy.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       -d "api_backend=http://$vertx_service_ip:8080" \
       -d "endpoint=https://$vertx_prod_route:443" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_service_proxy_update_response.xml
}

function promote() {

  echo -en "\n\npromote() " >> $LOG_FILE

  curl -v -k -X GET "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/services/$vertx_serviceId/proxy/configs/sandbox.json" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       | jq . > $API_RESPONSE_DIR/vertx_service_sandbox_proxy_config.json

  eval vertx_service_sandbox_proxy_config_versionId=\"`cat $API_RESPONSE_DIR/vertx_service_sandbox_proxy_config.json | jq '.proxy_configs[-1].proxy_config.version'`\"

  curl -v -k -X POST "https://3scale-admin.$OCP_WILDCARD_DOMAIN/admin/api/services/$vertx_serviceId/proxy/configs/sandbox/$vertx_service_sandbox_proxy_config_versionId/promote.json" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       -d "to=production" \
       | jq . > $API_RESPONSE_DIR/vertx_service_promotion_response.json

}

function test() {

  echo -en "\n\ntest() Will now test vertx service via production apicast gateway using the following variables:\n\tvertx_prod_route = $vertx_prod_route \n\tvertx_app_user_key=$vertx_app_user_key\n" >> $LOG_FILE

  ######  UNCOMMENT WHEN READY TO TEST
  eval results =\"`curl -f -v -k https://$vertx_prod_route/hello?user_key=$vertx_app_user_key`\"
  if [ $? -ne 0 ]; then
    echo "*** ERROR executing test"; exit 1
  fi
  echo -en "\ntest() result = $results\n" >> $LOG_FILE

}


echo args = $@

export API_RESPONSE_DIR=/tmp/amp_api_responses
export LOG_FILE=$API_RESPONSE_DIR/refresh_3scale_resources.log

while true; do
    case "$1" in
        --threescale_tenant_name) threescale_tenant_name="$2"; shift 2;;
        --ON_PREM_ACCESS_TOKEN) ON_PREM_ACCESS_TOKEN="$2"; shift 2;;
        --OCP_WILDCARD_DOMAIN) OCP_WILDCARD_DOMAIN="$2"; shift 2;;
        --vertx_prod_route) vertx_prod_route="$2"; shift 2;;
        --API_RESPONSE_DIR) API_RESPONSE_DIR="$2"; shift 2;;
        --LOG_FILE) LOG_FILE="$2"; shift 2;;
        --) shift; break;;
        *) break;;
    esac
done

check_variables
list_services
vertx_service
custom_plans
account
serviceProxy
promote
test
