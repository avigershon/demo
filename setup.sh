#!/bin/bash

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
    
    ACCOUNT=$(gcloud info --format='value(config.account)')

    kubectl create clusterrolebinding owner-cluster-admin-binding \
        --clusterrole cluster-admin \
        --user $ACCOUNT

    kubectl apply -f $home/rolebinding.yaml -o yaml
    kubectl apply -f $home/pv.yaml -o yaml
    
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh;
    chmod 700 get_helm.sh;
    ./get_helm.sh;

    helm init --wait --upgrade;

    #### install kompose
    #curl -L https://github.com/kubernetes/kompose/releases/download/v1.9.0/kompose-linux-amd64 -o kompose

    #chmod +x kompose
    #sudo mv ./kompose /usr/local/bin/kompose
    ####
    
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

    helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
    helm repo add stable http://storage.googleapis.com/kubernetes-charts
    
    #install_charts $branch $commit_hash $chart_path $home
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

if [ -z ${chart+x} ]; then 
   echo "chart is not set";
   system_setup;
   #setup; 
else 
   package_and_install_chart $chart; 
fi

