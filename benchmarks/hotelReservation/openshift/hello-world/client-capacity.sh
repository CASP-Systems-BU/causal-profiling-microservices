for (( c=2; c<=30; c=c+2 ))
do
  sed -e "s/corecount/${c}/g" hr-client.yaml > new-hr-client.yaml
  oc apply -f new-hr-client.yaml
  sleep 60
  ubuntuclient=$(oc -n hotel-res get pod | grep ubuntu-client- | cut -f 1 -d " ")
  oc exec "$ubuntuclient" -- bash -c "cd /root && git clone https://github.com/CASP-Systems-BU/causal-profiling-microservices.git"
  oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/hotelReservation/wrk2 && make clean && make"
  oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/hotelReservation/wrk2 && \
            ./wrk -D exp -t ${c} -c ${c} -d 60s -R 1000000 -L -P http://hello-world-svc.hotel-res.svc.cluster.local" > data-${c}.log
#        break
  oc delete -f new-hr-client.yaml
done

#./wrk -t 1 -c 10000 -d 120s -R 1000000 -L http://hello-world-svc.hotel-res.svc.cluster.local
#wrk2 -t 1 -c 4 -d 60s -R 1000000 -L http://a3f2a5af4c8b744c6a154222d67d0eab-507258469.us-east-1.elb.amazonaws.com:8080/