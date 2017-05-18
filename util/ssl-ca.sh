WORK_DIR=$HOME/ssl_ca

rm -rf $WORK_DIR
mkdir -p $WORK_DIR/certs $WORK_DIR/newcerts $WORK_DIR/private $WORK_DIR/crl

touch $WORK_DIR/index.txt
chmod 0664 $WORK_DIR/index.txt

echo "01" > $WORK_DIR/serial
chmod 0664 $WORK_DIR/serial

cat <<EOF > $WORK_DIR/ca.cnf
[ ca ]
default_ca = acme_ca

[ acme_ca ]
dir             = .                     # Where everything is kept
certs           = $dir/certs            # Where the issued certs are kept
crl_dir         = $dir/crl              # Where the issued crl are kept
database        = $dir/index.txt        # database index file.
#unique_subject  = no                   # Set to 'no' to allow creation of
                                        # several certificates with same subject.
new_certs_dir   = $dir/newcerts         # default place for new certs.
certificate     = $dir/acme-ca.crt      # The CA certificate
serial          = $dir/serial           # The current serial number
crlnumber       = $dir/crlnumber        # the current crl number
crl             = $dir/acme-ca.crl         # The current CRL
private_key     = $dir/private/acme-ca.key # The private key
RANDFILE        = $dir/private/.rand    # private random number file
x509_extensions = usr_cert              # The extentions to add to the cert
default_days    = 365                   # how long to certify for
default_crl_days= 30                    # how long before next CRL
default_md      = sha256                # use SHA-256 by default
preserve        = no                    # keep passed DN ordering
policy          = acme_policy
x509_extensions = certificate_extensions

[ acme_policy ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ certificate_extensions ]
basicConstraints=CA:false
EOF

chmod 0664 $WORK_DIR/ca.cnf
