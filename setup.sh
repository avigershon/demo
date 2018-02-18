ACCOUNT=$(gcloud info --format='value(config.account)')
kubectl create clusterrolebinding owner-cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $ACCOUNT
    
project=${PWD##*/}

kubectl create namespace $project;

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh;
chmod 700 get_helm.sh;
./get_helm.sh;

mkdir packages;

cd charts;
for d in * ; do
    echo "packaging $d chart...";
    helm package $d -d "./../packages";
done

cd ../packages;
for d in * ; do
    echo "installing $d chart...";
    helm install $d --namespace $project;
done
