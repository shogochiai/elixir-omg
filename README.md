Demo of logs scrubbing from STDOUT and fed by docker to host's syslog. Might be a good starting point for investigation.


Building docker container:

```
cd $ROOT
rm -rf deps _build
docker build . -t chain
```

Running:
```
docker run --log-driver=syslog -d chain:latest -c "cd apps/omg_api; iex -S mix run"
```o

Retrieving logs:
```
sudo cat /var/logs/syslog
```
