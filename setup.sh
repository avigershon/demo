#!/bin/bash

while [ $# -gt 0 ]; do
  case "$1" in
    --env=*)
      env="${1#*=}"
      project_setup env
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done

project_setup() {

  project=${PWD##*/}
  env = $1
  
  mkdir environments;
  mkdir environments/$env;
  mkdir environments/$env/packages;

  cd charts;
  for d in * ; do
      mkdir ./../environments/$env/packages/$d;
      echo "packaging $d chart...";
      helm package $d -d "./../environments/$env/packages/$d";
  done

  cd ../environments/$env/packages;
  
  for d in * ; do
      cd $d
      for package in * ; do
          echo "helm upgrade $env- $package -i --wait --namespace $project";
          helm upgrade $release $chart -i --wait --namespace $project;
      done
      cd ../
  done
}
    
system_setup () {

    ACCOUNT=$(gcloud info --format='value(config.account)')

    kubectl create clusterrolebinding owner-cluster-admin-binding \
        --clusterrole cluster-admin \
        --user $ACCOUNT

    kubectl apply -f rolebinding.yaml -o yaml

    kubectl create namespace $project;

    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh;
    chmod 700 get_helm.sh;
    ./get_helm.sh;

    helm init --wait;

    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    
    cd charts;
    
    for d in * ; do
        mkdir ./../environments/$env/packages/$d;
        echo "packaging $d chart...";
        helm package $d -d "./../environments/$env/packages/$d";
    done

    cd ../environments/$env/packages;

    for d in * ; do
        cd $d
        for package in * ; do
            echo "helm upgrade $env- $package -i --wait --namespace $project";
            helm upgrade $release $chart -i --wait --namespace $project;
        done
        cd ../
    done
}
