#!/bin/sh
JAVA_BIN=/usr/bin/java
AGENT_JAR=/etc/appoena/solaris/agent.jar
LOGFILE=/var/svc/log/appoena-solaris_agent:default.log

# Start in background, redirect output
nohup $JAVA_BIN -jar $AGENT_JAR >> $LOGFILE 2>&1 &
exit 0