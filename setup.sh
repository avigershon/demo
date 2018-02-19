ACCOUNT=$(gcloud info --format='value(config.account)')

kubectl create clusterrolebinding owner-cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $ACCOUNT
  
kubectl apply -f rolebinding.yaml -o yaml

project=${PWD##*/}

kubectl create namespace $project;

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh;
chmod 700 get_helm.sh;
./get_helm.sh;

helm init --wait;

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

mkdir packages;

cd charts;
for d in * ; do
    mkdir ./../packages/$d;
    echo "packaging $d chart...";
    helm package $d -d "./../packages/$d";
done

cd ../packages;
for d in * ; do
    cd $d
    for chart in * ; do
        echo "helm install $chart --name $d --namespace $project";
        helm install $chart --name $d --namespace $project;
    done
    cd ../
done
