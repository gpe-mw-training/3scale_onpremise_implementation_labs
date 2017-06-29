# Usage examples:
  # refresh_3scale_resources.sh --threescale_tenant_name 3scale --OCP_WILDCARD_DOMAIN $OCP_WILDCARD_DOMAIN --ON_PREM_ACCESS_TOKEN x7fwv5s26cs7ymqr




export API_RESPONSE_DIR=/tmp/amp_api_responses
export LOG_FILE=$API_RESPONSE_DIR/refresh_3scale_resources.log

mkdir -p $API_RESPONSE_DIR

function check_variables() {
  if [ "x$threescale_tenant_name" == "x"  ]; then
    echo "Please ensure the following environment variable is set: threescale_tenant_name"
    exit 1;
  fi
  if [ "x$ON_PREM_ACCESS_TOKEN" == "x"  ]; then
    echo "Please ensure the following environment variable is set: ON_PREM_ACCESS_TOKEN"
    exit 1;
  fi
  if [ "x$OCP_WILDCARD_DOMAIN" == "x"  ]; then
    echo "Please ensure the following environment variable is set: OCP_WILDCARD_DOMAIN"
    exit 1;
  fi

  echo -en "threescale_tenant_name = $threescale_tenant_name : ON_PREM_ACCESS_TOKEN = $ON_PREM_ACCESS_TOKEN : OCP_WILDCARD_DOMAIN = $OCP_WILDCARD_DOMAIN\n\n" > $LOG_FILE
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
  curl -v -k -X GET "https://$threescale_tenant_name-admin.$OCP_WILDCARD_DOMAIN/admin/api/services/$vertx_serviceId/service_plans.xml" \
       -d "access_token=$ON_PREM_ACCESS_TOKEN" \
       | xmlstarlet format --indent-tab > $API_RESPONSE_DIR/vertx_default_service_plan.xml

  eval vertx_servicePlanId=\"`xmlstarlet sel -t -m '//plan' -v 'id' -n $API_RESPONSE_DIR/vertx_default_service_plan.xml`\"
  echo -en "\nvertx_service() vertx_servicePlanId = $vertx_servicePlanId" >> $LOG_FILE
}


function custom_plans() {

  echo -en "\n\ncustom_plans() creating 3scale custom plans for vertx_service" >> $LOG_FILE

  ##### IMPLEMENT ME: CREATION OF APP PLAN and HIT METRIC  #######

  ##### IMPLEMENT ME: CREATION OF ACCOUNT PLAN  #######
}

function account() {

  echo -en "\n\naccount() creating account and user " >> $LOG_FILE

  ##### IMPLEMENT CREATION OF ACCOUNT and USER  #######

}

function serviceProxy() {
  echo -en "\n\nserviceProxy() creating account and user " >> $LOG_FILE

  ##### IMPLEMENT ME:    CREATION OF ACCOUNT and USER  #######
}


echo args = $@

while true; do
    case "$1" in
        --threescale_tenant_name) threescale_tenant_name="$2"; shift 2;;
        --ON_PREM_ACCESS_TOKEN) ON_PREM_ACCESS_TOKEN="$2"; shift 2;;
        --OCP_WILDCARD_DOMAIN) OCP_WILDCARD_DOMAIN="$2"; shift 2;;
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
