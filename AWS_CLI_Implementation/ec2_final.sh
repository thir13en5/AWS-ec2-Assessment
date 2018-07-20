#!/bin/sh

#Author:Chaitanya Malpe

#Date:19/07/2018

#This shell script creates two aws ec2 instances each with HTTP application and attached elastic load balancer

#creating two aws ec2 instances with respective user_datas and also initializing instance ids and then printing them
id1=$(aws ec2 run-instances --image-id ami-b70554c8 --count 1 --instance-type t2.micro --key-name MyKeyPairv1 --security-group-ids sg-6fa97b25 --subnet-id subnet-de0385f2 --tag-specifications 'ResourceType=instance, Tags=[{Key=Name, Value=Chaitanyav1}]' --user-data file://launch_script_v1.txt --query 'Instances[*].InstanceId' --output text)
aws ec2 describe-instances --instance-ids $id1 > instance1.json
cat instance1.json

id2=$(aws ec2 run-instances --image-id ami-b70554c8 --count 1 --instance-type t2.micro --key-name MyKeyPairv2 --security-group-ids sg-6fa97b25 --subnet-id subnet-124b752e --tag-specifications 'ResourceType=instance, Tags=[{Key=Name, Value=Chaitanyav2}]' --user-data file://launch_script_v2.txt --query 'Instances[*].InstanceId' --output text)
aws ec2 describe-instances --instance-ids $id2 > instance2.json
cat instance2.json

echo $id1
echo $id2

#creating a simple elastic load balancer
aws elb create-load-balancer --load-balancer-name my-load-balancer --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" --subnets subnet-de0385f2 subnet-124b752e --security-groups sg-5b8d5111

#enabling Cross Zone Load Balancing 
aws elb modify-load-balancer-attributes --load-balancer-name my-load-balancer --load-balancer-attributes "{\"CrossZoneLoadBalancing\":{\"Enabled\":true}}"

#Configuring health checkups for index.html
aws elb configure-health-check --load-balancer-name my-load-balancer --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=5

#sleep for 10 mins before adding the newly created instances to the load balancer
sleep 10m

#now attaching the newly created ec2 instances to the load balancer
aws elb register-instances-with-load-balancer --load-balancer-name my-load-balancer --instances $id1 $id2

#after 20 mins of running terminate both instances and load balancer
sleep 10m

#terminating ec2 instances by InstanceId
aws ec2 terminate-instances --instance-ids $id1 $id2

sleep 5m

#removing load balancer
aws elb delete-load-balancer --load-balancer-name my-load-balancer
echo("Load Balancer Removed..........................."
