
startTenant=2
endTenant=3

master_access_token=ga7f0bqe
OCP_WILDCARD_DOMAIN=$OCP_WILDCARD_DOMAIN
tenant_passwd=admin
create_tenant_url=https://$OCP_PROJECT_PREFIX-master-admin.$OCP_WILDCARD_DOMAIN/master/api/providers.xml
output_dir=/tmp/3scale_tenant

function createAndActivateTenants() {

    echo -en "\n\nCreating tenants $startTenant through $endTenant  \n";
    

    for i in $(seq ${startTenant} ${endTenant}) ; do
        orgName=acme$i;
        userId=user$i;
        email=user$1@$OCP_WILDCARD_DOMAIN
  
       # 1) Create tenant 
       curl -v  \
            -k \
            -X POST \
            -d access_token=$master_access_token \
            -d org_name=$orgName \
            -d username=$userId \
            -d email=$userId%40$OCP_WILDCARD_DOMAIN \
            -d password=$tenant_passwd \
            $create_tenant_url > $output_dir/$orgName_tenant_signup.xml

        # 2)  activate new user

        # 3) Create corresponding route
        oc create route edge $orgName-provider --service=system-provider --hostname=$orgName-admin.$OCP_WILDCARD_DOMAIN

        echo -en "\ncreated tenant with orgName= $orgName \n";
    done;

}

mkdir -p $output_dir
createAndActivateTenants
