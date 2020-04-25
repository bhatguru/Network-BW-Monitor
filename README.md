# Network-BW-Monitor
This is Mainly Developed for Monitoring the Internet Leased Lines connected to physical servers, this is tested and deployed on production(centos6.x).

## More context on Developing this
We have number of physical servers hosted on varios DC across india and outside india, and we use to get lot of issues of overutilising Network Bandwidth, network flapping etc. ther was no way to monitor this and same has been assigned me to find a solution.

I Will be sharing this here thinking that, this will be helping some one who is in the same kind of setup/use cases,
i will assume that we have working data/metric pipeline and visualisation setup, in my organisation we have ELK Stack and some Centralised log server, considering that, we can see the Architecture, and i will explain further each and every components of the Architecture and code, so that you can modify the script and configs according to you'r requirement

Note:- This configs/paths may not directly work on your environment, would suggest you to go through the configs and modify them.

## Architecture Diagram:-
![Architecture Diagram](/images/img1.jpg)

## Final Dashboard: - 
![Dahboard](/images/img2.png)

In the above diagram, in the lef side we can see multiple regions/states(DCs) such as Karnataka, Delhi, Mumbai etc, each of the regions having multiple physical servers running and they are connected to multiple physical Internet lines of different different ISPs such as Vodafone, TCL, Reliance etc.

We basically have 3 files
### 1. network_bandwidth_config.json
    Here we define the configs such as `hostname`, `circuitID` `interfacename` for which interface connected and `operator` etc, go and modify accordingly, circuitid and hostnames are unique identifiers here.

### 2. network_bandwidth_monitor.cron
    This is the cron file which runs the script and pushes data to the pipeline every 10 sec.
    This holds the config file path and script path, modify the file paths here, you can ignore SIP conf file in this.
    copy this file under /etc/cron.d

### 3. network_bandwidth.sh
    Dependencies:
    - ifstat (please use linux repos such as Yum to install this package)
    - jq (this can also be installed using Yum ) 

    This is the main script which does the job, this is a simple Bash script, which uses ifstat and Jq latest version to capture the utilisation and parsing json data from configs.
    This basically monitors each and every active interfaces and send the data to local rsyslog port(we are using rysylog in the client to push the metrics) you can use similar client or you can use beats in the client to ship the logs.
    here in our setup rsyslog ships the log to centrelised log server in Cloud Environment, from there file beat, picks the log and send it to logstash, then logstash will send to elastic serach, this is how our pipeline is set, it may differ for your environment, you have to modify the local output redirecting path to your setup, then finally visualise it in Kibana/ any other visualisatioin tool and done.


### Thanks
 

    







