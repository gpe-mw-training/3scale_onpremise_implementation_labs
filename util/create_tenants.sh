
startTenant=1
endTenant=1

master_access_token=ga7f0bqe
OCP_WILDCARD_DOMAIN=$OCP_WILDCARD_DOMAIN
tenant_passwd=admin
create_tenant_url=https://$OCP_PROJECT_PREFIX-master-admin.$OCP_WILDCARD_DOMAIN/master/api/providers.xml
output_dir=/tmp/3scale_tenant
access_token_mapping_file=$output_dir/access_token_mapping_file.txt

function createAndActivateTenants() {

    echo -en "\n\nCreating tenants $startTenant through $endTenant  \n";
    

    for i in $(seq ${startTenant} ${endTenant}) ; do
        orgName=user$i-3scale;
        userId=user$i;
        output_file=$orgName-tenant-signup.xml
  
       # 1) Create tenant 
       curl -k  \
            -X POST \
            -d access_token=$master_access_token \
            -d org_name=$orgName \
            -d username=$userId \
            -d email=$userId%40$OCP_WILDCARD_DOMAIN \
            -d password=$tenant_passwd \
            $create_tenant_url > $output_dir/$output_file

        # 2) Retrieve access_token
        eval access_token=\"`xmlstarlet sel -t -m '//access_token' -v 'value' -n $output_dir/$output_file`\"


        # 3)  activate new user
        eval account_id=\"`xmlstarlet sel -t -m '//account' -v 'id' -n $output_dir/$output_file`\"
        eval user_id=\"`xmlstarlet sel -t -m '///user[state = "pending"]' -v 'id' -n $output_dir/$output_file`\"
        echo -en "\nactivating new user. account_id = $account_id. user_id = $user_id \n";
        activate_user_url=https://$OCP_PROJECT_PREFIX-master-admin.$OCP_WILDCARD_DOMAIN/admin/api/accounts/$account_id/users/$user_id/activate.xml


        echo -en "\n\n" >> $output_dir/$output_file
        curl -k \
             -X PUT \
             -d access_token=$master_access_token \
             $activate_user_url >> $output_dir/$output_file


        # 4) Create corresponding route
        oc create route edge $orgName-provider --service=system-provider --hostname=$orgName-admin.$OCP_WILDCARD_DOMAIN

        echo -en "\ncreated tenant with orgName= $orgName. \n\tOutput file at: $output_dir/$output_file  \n\taccess_token = $access_token \n";

        echo -en "\n$userId   $access_token" >> $access_token_mapping_file
    done;

    echo -en "\n\n\naccess_token_mapping_file available at: $access_token_mapping_file \n";

}

mkdir -p $output_dir
createAndActivateTenants
