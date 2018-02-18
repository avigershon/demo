curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh;
chmod 700 get_helm.sh;
./get_helm.sh;

mkdir packages;

cd charts;
for d in * ; do
    echo "packaging $d chart...";
    helm package $d -d "./../packages";
done
