# Purpose


function createPVdefs() {

echo -en "\n\n Creating the following PVs $startVol .. $endVol of the following size: $volsize   ********** \n";

for i in $(seq ${startVol} ${endVol}) ; do
volume=`echo vol$i`;

cat <<EOF > /tmp/pvs/${volume}
{
    "apiVersion": "v1",
    "kind": "PersistentVolume",
    "metadata": {
        "name": "${volume}"
    },
    "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteOnce", "ReadWriteMany" ],
    "nfs": {
        "path": "/var/nfs/${volume}",
        "server": "${nfs_server_ip}"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
    }
}
EOF
echo "created def file for: ${volume}";
done;

}

mkdir /tmp/pvs

nfs_server_ip=192.168.122.254
volsize="2Gi"
startVol=1
endVol=4
createPVdefs

cd /tmp/pvs
cat vol1 vol2 vol3 vol4 | oc create -f - -n default --as=system:admin
