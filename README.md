Demo of logs scrubbing from STDOUT and fed by docker to host's syslog. Might be a good starting point for investigation.

All changes to apps/*/lib/application.ex were done to remove the need to have geth, database, config etc.


Building docker container:

```
cd $ROOT
rm -rf deps _build
docker build . -t chain
```

Running:
```
docker run --log-driver=syslog -d chain:latest -c "cd apps/omg_api; iex -S mix run"
```

Retrieving logs:
```
sudo cat /var/logs/syslog
```

Logs should look like this:
```
Oct 24 17:10:05 ppsh dbc355914c24[2428]: 15:10:05.680 [warn]  tick # 731
Oct 24 17:10:06 ppsh dbc355914c24[2428]: 15:10:06.681 [warn]  tick # 732
Oct 24 17:10:07 ppsh dbc355914c24[2428]: 15:10:07.682 [warn]  tick # 733
Oct 24 17:10:08 ppsh dbc355914c24[2428]: 15:10:08.683 [warn]  tick # 734
```
