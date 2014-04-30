#!/bin/bash
REGION='ap-southeast-1'
#export AWS_CONFIG_FILE=/home/vishnu/awscred
printhelp() {
echo "
Usage: ip-swap.sh [OPTION]...
  -a,    --alter          Give --alter swap for swapping and --alter revert for reverting the IP
  -f,    --from           From which server the Elastic ip should change
  -t,    --to             To which server the Elastic ip should put
  -h,    --help           Display help file
"
}
[ "$1" == "" ] && printhelp && exit;

while [ "$1" != "" ]; do
  case "$1" in
    -a    | --alter )              ALTER_TAG=$2; shift 2 ;;
    -f    | --from )               FROM_TAG=$2; shift 2 ;;
    -t    | --to )                 TO_TAG=$2; shift 2 ;;
    -h    | --help )               echo "$(printhelp)"; exit; shift; break ;;
  esac
done

if [ -z "$ALTER_TAG" ]; then
    echo "swap / revert option is empty"
    exit;
fi

from_ip_details(){


FROM_PUB_IP=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$FROM_TAG --query Reservations[*].Instances.NetworkInterfaces.PrivateIpAddresses.Association.PublicIp --output text`
FROM_PRIVATE_IP_PRIMARY=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$FROM_TAG --query Reservations[*].Instances.NetworkInterfaces.PrivateIpAddresses | grep -A 1 "true" | grep "PrivateIpAddress" | awk -F"\"" '{print $4}'`
FROM_PRIVATE_IP_SECONDARY=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$FROM_TAG --query Reservations[*].Instances.NetworkInterfaces.PrivateIpAddresses | grep -A 1 "false" | grep "PrivateIpAddress" | awk -F"\"" '{print $4}'`
FROM_INSTANCE_ID=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$FROM_TAG --query Reservations[*].Instances.InstanceId --output text`
FROM_IP_ALLOCATION_ID=`aws ec2 describe-addresses --public-ips $FROM_PUB_IP --region $REGION | grep -i "AllocationId" | awk -F "\"" '{print $4}'`

}

from_ip_details

echo "BEFORE SWAPPING"

from_ip_print(){
echo "########################################################"
echo "Instance Details of $FROM_TAG"
echo "FROM Public IP - $FROM_PUB_IP"
echo "FROM Primary private IP - $FROM_PRIVATE_IP_PRIMARY"
echo "FROM secondary private IP - $FROM_PRIVATE_IP_SECONDARY"
echo "FROM ALLOCATION ID  - $FROM_IP_ALLOCATION_ID"
echo "FROM INSTANCE ID  - $FROM_INSTANCE_ID"

echo "########################################################"
}

from_ip_print

to_ip_details()
{
TO_PUB_IP_PRIMARY=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$TO_TAG --query Reservations[*].Instances.NetworkInterfaces.PrivateIpAddresses | grep -B 4 "true" | grep "PublicIp" | awk -F "\"" '{print $4}'`
TO_PUB_IP_SECONDARY=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$TO_TAG --query Reservations[*].Instances.NetworkInterfaces.PrivateIpAddresses | grep -B 4 "false" | grep "PublicIp" | awk -F "\"" '{print $4}'`
TO_PRIVATE_IP_PRIMARY=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$TO_TAG --query Reservations[*].Instances.NetworkInterfaces.PrivateIpAddresses | grep -A 1 "true" | grep "PrivateIpAddress" | awk -F"\"" '{print $4}'`
TO_PRIVATE_IP_SECONDARY=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$TO_TAG --query Reservations[*].Instances.NetworkInterfaces.PrivateIpAddresses | grep -A 1 "false" | grep "PrivateIpAddress" | awk -F"\"" '{print $4}'`
TO_INSTANCE_ID=`aws ec2 describe-instances --region $REGION --filters Name=tag-value,Values=$TO_TAG --query Reservations[*].Instances.InstanceId --output text`
TO_IP_ALLOCATION_ID=`aws ec2 describe-addresses --public-ips $TO_PUB_IP_PRIMARY --region $REGION | grep -i "AllocationId" | awk -F "\"" '{print $4}'`
TO_SEC_IP_ALLOCATION_ID=`aws ec2 describe-addresses --public-ips $TO_PUB_IP_SECONDARY --region $REGION | grep -i "AllocationId" | awk -F "\"" '{print $4}'`

}

to_ip_details

to_ip_print()
{
echo "########################################################"
echo "Instance Details of $TO_TAG"
echo "TO Primary Public IP - $TO_PUB_IP_PRIMARY"
echo "TO SECONDARY IP - $TO_PUB_IP_SECONDARY"
echo "TO Primary private IP - $TO_PRIVATE_IP_PRIMARY"
echo "TO secondary private IP - $TO_PRIVATE_IP_SECONDARY"
echo "TO ALLOCATION ID  - $TO_IP_ALLOCATION_ID"
echo "TO SECONDARY ALLOCATION ID - $TO_SEC_IP_ALLOCATION_ID"
echo "TO INSTANCE ID  - $TO_INSTANCE_ID"

echo "########################################################"
}

to_ip_print


echo "alter tag is $ALTER_TAG"

if [ "$ALTER_TAG" == "swap" ];then
aws ec2 associate-address --allow-reassociation --private-ip-address $TO_PRIVATE_IP_SECONDARY --instance-id $TO_INSTANCE_ID --region $REGION --allocation-id $FROM_IP_ALLOCATION_ID
fi
if [ "$ALTER_TAG" == "revert" ];then
aws ec2 associate-address --allow-reassociation --private-ip-address $FROM_PRIVATE_IP_PRIMARY --instance-id $FROM_INSTANCE_ID --region $REGION --allocation-id $TO_SEC_IP_ALLOCATION_ID
fi

echo "completed IP Swapping and current Details"
from_ip_details
from_ip_print
to_ip_details
to_ip_print
exit
