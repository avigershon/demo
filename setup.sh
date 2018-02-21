#!/bin/bash

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare $v="$2"
   fi

  shift
done
   
setup () {

  env=$1;
  recreate=$2;
  home=$PWD
  
  #create env folders
  mkdir $home/environments;
  mkdir $home/environments/$env;
  mkdir $home/environments/$env/packages;
  
  if [ "$recreate" == "true" ]; then
      system_setup
  #else
  #  kubectl create namespace $env;
  #  install_chart $env
  fi
  
  install_chart $env $recreate
  
}

system_setup () {

    home=$PWD
    
    ACCOUNT=$(gcloud info --format='value(config.account)')

    kubectl create clusterrolebinding owner-cluster-admin-binding \
        --clusterrole cluster-admin \
        --user $ACCOUNT

    kubectl apply -f $home/rolebinding.yaml -o yaml

    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh;
    chmod 700 get_helm.sh;
    ./get_helm.sh;

    helm init --wait;

    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    
    install_chart $env true
}

install_chart() {

  project=${PWD##*/}
  home=$PWD
  env=$1
  recreate=$2
  namespace=$project-$env;
  
  kubectl create namespace $namespace;
  
  cd $home/charts/;
    
  for chart in * ; do
      mkdir $home/environments/$env/packages/$chart;
      echo "packaging $chart chart...";
      helm package $chart -d "$home/environments/$env/packages/$chart";
  done

  cd $home/environments/$env/packages;
  
  echo "current folder=$PWD";
  
  for chart in * ; do
  
    cd $home/environments/$env/packages/$chart;

    echo "current folder=$PWD";

    for package in * ; do
    
      if [ "$recreate" == "true" ]; then
        #namespace="kube-system";
        
        echo "helm del $chart --purge";
        helm del $chart --purge;
        
        echo "helm install $package --name $chart --wait --namespace $namespace --set namespace=$namespace";
        helm install $package --name $chart --wait --namespace $env --set namespace=$namespace;
      else
        #namespace=$env
        echo "helm upgrade $chart $package -i --wait --namespace $namespace";
        helm upgrade $chart $package -i --wait --namespace $namespace;
      fi
      
    done
    
  done
}
 
setup $env $recreate;

