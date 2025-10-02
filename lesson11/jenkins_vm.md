nikita@nikita:~$ systemctl status jenkins.service
```
● jenkins.service - Jenkins Continuous Integration Server
     Loaded: loaded (/lib/systemd/system/jenkins.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2025-10-02 18:19:40 UTC; 1h 29min ago
   Main PID: 28547 (java)
      Tasks: 46 (limit: 4550)
     Memory: 1.7G
     CGroup: /system.slice/jenkins.service
             └─28547 /usr/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.wa
```
