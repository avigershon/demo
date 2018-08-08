#!/bin/bash

# Step 1: Create EKS Cluster
# Step 1.1: create IAM role
# Step 2: Create EC2 Instance with kubectl configured
# Step 3: Launch and Configure Amazon EKS Worker Nodes 
#   - s3 location : https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/amazon-eks-nodegroup.yaml
#   - Stack name : Ashford-Worker-Nodes-(n)
#   - ClusterControlPlaneSecurityGroup : DataTeam_Rules
#   - Node image : ami-dea4d5a1
#   - KeyName : data_team_key
#   - VPC : vpc-888730ec
#   - Subnets : NGW-subnet
#   - After it complete get the NodeIntanceRole arn
# Step 4: enable worker nodes to join your cluster
#   - curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/aws-auth-cm.yaml
#   - change the Node intance role with the one you got above
#   - aws cloudformation describe-stack-instance --stack-set-name ashford_3
#   - kubectl apply -f aws-auth-cm.yaml
# Step 5: install helm (we need to add inbound so helm client can work with tiller server)

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare $v="$2"
   fi

  shift
done
   
setup () {

  #env=$1;
  #recreate=$2;
  home=$PWD;
  commit_hash=$(git log --format="%H" -n 1);
  branch=$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/");
  
  rm -rf $home/environments;
  
  #create env folders
  mkdir $home/environments;
  mkdir $home/environments/$branch;
  mkdir $home/environments/$branch/packages;
  mkdir $home/environments/$branch/packages/charts;
  mkdir $home/environments/$branch/packages/charts/global;
  
  #if [ "$recreate" == "true" ]; then
  system_setup
  #else
  #  kubectl create namespace $env;
  #  install_chart $env
  #fi
  
  chart_path="charts"
  install_charts $branch $commit_hash $chart_path $home
  
}

system_setup () {

    home=$PWD
    chart_path="cluster"
    
    # TBD for AWS
    # ACCOUNT=$(gcloud info --format='value(config.account)')

    # kubectl create clusterrolebinding owner-cluster-admin-binding \
    #    --clusterrole cluster-admin \
    #    --user $ACCOUNT

    #kubectl apply -f $home/rolebinding.yaml -o yaml
    #kubectl apply -f $home/pv.yaml -o yaml
    
    aws eks describe-cluster --name Ashford_two --query cluster.status
    aws eks describe-cluster --name Ashford_two --query cluster.endpoint
    aws eks describe-cluster --name Ashford_two --query cluster.certificateAuthority.data
    
    kubectl create serviceaccount dashboard -n default
    
    curl -o aws-iam-authenticator https://amazon-eks.s3-uswest-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator
    curl -o aws-iam-authenticator.sha256 https://amazon-eks.s3-uswest-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iamauthenticator.sha256
    
    chmod +x ./aws-iam-authenticator
   
    cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
  
    echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
    
    
    #curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh;
    chmod 700 get_helm.sh;
    
    export PATH=$PATH:/usr/local/bin;
    ./get_helm.sh;

    helm init --wait --upgrade;

    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

    helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
    helm repo add stable http://storage.googleapis.com/kubernetes-charts
}

install_charts() {
   
  branch=$1
  commit_hash=$2
  path=$3
  home=$4
  
  cd $home
  project=${PWD##*/}
  env=$project-$branch;
  
  if [ "$path" == "cluster" ]; then
      namespace="default";
  else
      namespace=$project-$branch;
  fi
   
  kubectl create namespace $namespace;
  #kubectl config set-context $(kubectl config current-context) --namespace=$namespace;
  
  cd $home/$path/;
    
  for chart in * ; do
      mkdir $home/environments/$branch/packages/$path;
      mkdir $home/environments/$branch/packages/$path/$chart;
      echo "packaging $chart chart...";
      helm package $chart -d "$home/environments/$branch/packages/$path/$chart";
  done

  cd $home/environments/$branch/packages/$path;
  
  echo "current folder=$PWD";
  
  for chart in * ; do
  
    #release_name=$namespace-$chart;
    release_name=$chart;

    cd $home/environments/$branch/packages/$path/$chart;

    echo "current folder=$PWD";

    for package in * ; do
      #if [ "$chart" != "cluster" ]; then
         upgrade_chart $chart $package $namespace $release_name $env|| install_chart $chart $package $namespace $release_name $env
      #fi
      #if [ "$recreate" == "true" ]; then
      #  install_chart $chart $package $namespace
      #else
      #  upgrade_chart $chart $package $namespace || install_chart $chart $package $namespace
      #fi
      
    done
    
  done
}
 
install_chart () {
   chart=$1
   package=$2
   namespace=$3
   release_name=$4
   env=$5
   
   echo "helm del $chart --purge";
   helm del $chart --purge;
        
   echo "helm install $package --name $release_name --namespace $namespace --wait --set project=$env";
   helm install $package --name $release_name --namespace $namespace --wait --set project=$env;
}

upgrade_chart () {
   chart=$1
   package=$2
   namespace=$3
   release_name=$4
   env=$5
   
   echo "helm upgrade $release_name $package -i --namespace $namespace --wait --set project=$env";
   helm upgrade $release_name $package -i --namespace $namespace --wait --set project=$env;
}

package_and_install_chart () {
   
   path=`dirname "$1"`
   chart=`basename "$1"`
   
   project=${PWD##*/}
   branch=$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/");
   env=$project-$branch;
   
   home=$PWD

   echo "********************$PWD******************************";

   if [ "$path" == "cluster" ]; then
      namespace="default";
   else
      namespace=$project-$branch;
   fi
   
   kubectl create namespace $namespace;
   
   cd $home/$path/;
   echo "********************$PWD******************************";

   rm -rf $home/environments/$branch/packages/$path/$chart;
   
   mkdir $home/environments;
   mkdir $home/environments/$branch;
   mkdir $home/environments/$branch/packages;
   mkdir $home/environments/$branch/packages/$path;
   mkdir $home/environments/$branch/packages/$path/$chart;
   
   echo "packaging $chart chart...";
   helm package $chart -d "$home/environments/$branch/packages/$path/$chart";
   echo "helm package $chart -d $home/environments/$branch/packages/$path/$chart";

   release_name=$chart;

   cd $home/environments/$branch/packages/$path/$chart;

   echo "current folder=$PWD";

   echo "********************$PWD******************************";

   for package in * ; do
      echo "********************$PWD******************************";

      echo "chart=$chart ,package=$package ,namespace=$namespace ,release_name=$release_name ,env=$env";
      upgrade_chart $chart $package $namespace $release_name $env|| install_chart $chart $package $namespace $release_name $env
   done
}

aws_client_setup () {

   ClusterControlPlaneSecurityGroup	sg-20459f57	
   ClusterName	ashford_3	
   KeyName	data_team_key	
   NodeAutoScalingGroupMaxSize	3	
   NodeAutoScalingGroupMinSize	1	
   NodeGroupName	ashford-3-node-group	
   NodeImageId	ami-dea4d5a1	
   NodeInstanceType	t2.medium	
   Subnets	subnet-a0d085e8	
   VpcId

   cleanClusterName=${ClusterName/_/-}
   
   echo "Creating EKS worker nodes"
   aws cloudformation create-stack --stack-name eks-$cleanClusterName-worker-nodes --template-url https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/amazon-eks-nodegroup.yaml --parameters ParameterKey=ClusterName,ParameterValue=$clusterid ParameterKey=SubnetIDs,ParameterValue=$subnsets
   #curl -o aws-iam-authenticator "https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator";
   #chmod +x ./aws-iam-authenticator;
   #cp ./aws-iam-authenticator /usr/bin/aws-iam-authenticator;
   
   #aws-iam-authenticator help;

   mkdir -p ~/.kube;
   mkdir -p ~/.kube/$ClusterName;
   
   /bin/cat <<EOM >~/.kube/$ClusterName/config
apiVersion: v1
clusters:
- cluster:
    server: $( aws eks describe-cluster --name $ClusterName --query cluster.endpoint)
    certificate-authority-data: $( aws eks describe-cluster --name $ClusterName --query cluster.certificateAuthority.data)
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "$ClusterName"
      #  - "-r"
      #  - "arn:aws:iam::583658998514:role/EKS_Role"
      #env:
      #  - name: AWS_PROFILE
      #    value: "ashford"
EOM

   export KUBECONFIG=~/.kube/$ClusterName/config;
   echo 'export KUBECONFIG=~/.kube/$ClusterName/config' >> ~/.bashrc
   
   /bin/cat <<EOM >~/.kube/$ClusterName/aws-auth-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn:  $( aws cloudformation describe-stacks --stack-name eks-$cleanClusterName-worker-nodes --query 'Stacks[*].Outputs[*].OutputValue' --output text)
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOM

   kubectl apply -f ~/.kube/$ClusterName/aws-auth-cm.yaml;
   
}

if [ -z ${chart+x} ]; then 
   echo "chart is not set";
   if [ -z ${ClusterName+x} ]; then 
      echo "ClusterName is not set";
      system_setup;
   else 
      echo "ClusterName is set";
      aws_client_setup $ClusterName; 
   fi 
else 
   echo "chart is set";
   package_and_install_chart $chart; 
fi
