function mkpasswd
    pwgen -Bs $argv 1 |pbcopy |pbpaste;
end

function ll
     aws ec2 describe-instances --filter Name=tag:Name,Values=$argv
end
function list
     aws ec2 describe-instances --query 'Reservations[].Instances[].[ InstanceId,[Tags[?Key==`Name`].Value][0][0],State.Name,InstanceType,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress ]' --filters Name=instance-state-name,Values=running
end
function listapi
    aws ec2 describe-instances --query 'Reservations[].Instances[].[ InstanceId,[Tags[?Key==`Name`].Value][0][0],State.Name,InstanceType,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress ]' --filters Name=tag:STACK,Values=API
end

function lli
    aws ec2 describe-instances --query 'Reservations[].Instances[].[ InstanceId,[Tags[?Key==`Name`].Value][0][0],State.Name,InstanceType,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress ]' --instance-ids $argv
end

function listas
    aws autoscaling describe-auto-scaling-instances
end

function llb
    aws elb describe-instance-health --load-balancer-name $argv
end

function listlb
    aws elb describe-load-balancers | grep LoadBalancerName
end

function exec_all
    for x in (list | awk -F"|" '{print $8}' | sed '/^\s*$/d'| tr -d " \t\s")
        ssh -o 'StrictHostKeyChecking=no' -i .ssh/key.pem -l ec2-user $x "hostname; $argv"
    end
end
set -gx PATH ~/Library/Python/2.7/bin $PATH
