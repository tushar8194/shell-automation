#!/bin/bash
host=`echo $1 | tr '[:upper:]' '[:lower:]'`#echo $host
if [[ -z "$host"  ]] ; then echo 'wrong parmeters supplied params host app/sub_app [emailid]'exit 1fi
export APP=`echo $2 | tr '[:upper:]' '[:lower:]' | cut -d "/" -f 1`#echo $APP
if [ -z "$APP"  ] ; thenecho 'wrong parmeters supplied params host app/sub_app [emailid]'exit 1fi
export SUB_APP=`echo $2 | tr '[:upper:]' '[:lower:]' | cut -d "/" -f 2`#echo $SUB_APP

if [ -z "$SUB_APP"  ] ; thenecho 'wrong parmeters supplied params host app/sub_app [emailid]'exit 1fi
EMAIL_ADDRESS=$3
if [ $host == 'littlered' ] ; thenpropertiesFile=/userapps/hdp/SVCMPHDS/GSTLLTY/edgenodelocal/${APP}/${SUB_APP}/jobprops/${SUB_APP}.propertiestempFile=/userapps/hdp/SVCMPHDS/GSTLLTY/edgenodelocal/${APP}/${SUB_APP}/jobprops/${SUB_APP}.properties_tmpelif [ $host == 'bigred' ] ; thenpropertiesFile=/userapps/hdp/SVCMPHDP/GSTLLTY/edgenodelocal/${APP}/${SUB_APP}/jobprops/${SUB_APP}.propertiestempFile=/userapps/hdp/SVCMPHDP/GSTLLTY/edgenodelocal/${APP}/${SUB_APP}/jobprops/${SUB_APP}.properties_tmpelse    echo 'Invalid argument for host'    exit 1ficat $propertiesFile | sed -e '/#MARK-1/,$d' > $tempFile. $tempFile

echo "starting klist"
unset HADOOP_TOKEN_FILE_LOCATION;hdps=`echo ${DEPLOYMENT_ID_LOWERCASAE:5:3}`kinit -kt ${HOME_DIR}/keytab-${hdps}/${DEPLOYMENT_ID_UPPERCASE}.keytab ${DEPLOYMENT_ID_UPPERCASE}@${HOST_UPPERCASE}.TARGET.COM


typeset -u gstScript=`basename $0 | cut -d. -f1`

jobName=${SUB_APP}mkdir -p ${LOG_DIR}logfile=${LOG_DIR}/${jobName}.log
echo "Jobname is $jobName" | tee >$logfile
#########################Trigger the Job and poll the status #####################################################################################
echo "Initiating Oozie Job ..."
if [ ! -f ${LOG_DIR}/oozie_status_${jobName}.txt ]then    oozieJobId=`oozie job -config ${propertiesFile} -run -oozie ${OOZIE_URL} -D CurDate=$(date +%Y-%m-%d) | grep "job:" | cut -d':' -f2| sed "s/^[ ]*//"`    echo " ***oozie job id is $oozieJobId****"else    echo "Restart of job initiated" | tee >>$logfile    oozieJobId=`grep "oozieJobId=" ${LOG_DIR}/oozie_status_${jobName}.txt | cut -d'=' -f2| sed "s/^[ ]*//"`
    # get the nodes which needs to be skipped for rerun    oozienodes=`oozie job -oozie ${OOZIE_URL} -info $oozieJobId | grep "SUCCEEDED" | cut -d "@" -f2 | cut -d " " -f1 | paste -d, -s | awk -F", " '{for (i=NF;i;i--) printf "%s ",$i; print ""}'`
    echo "**** $oozienodes ****"
    # rerun the oozie workflowoozie job -oozie ${OOZIE_URL} -rerun ${oozieJobId} -D oozie.wf.rerun.failnodes=true#oozie job -oozie ${OOZIE_URL} -rerun ${oozieJobId} -D oozie.wf.rerun.skip.nodes=$oozienodes    #oozie job -oozie ${OOZIE_URL} -D oozie.wf.rerun.skip.nodes=$oozienodes, -config ${propertiesFile} -rerun ${oozieJobId} -D CurDate=$(date +%Y-%m-%d)
    echo "Restart of the oozie job id is $oozieJobId" | tee >>$logfilefi
echo "Oozie Job Initiated  ID : ${oozieJobId}"if [ ! -n "${oozieJobId}" ]then    echo "Subject : Oozie job Not Created" > ${LOG_DIR}/${jobName}_oozie_status.txt    chmod 775 ${LOG_DIR}/${jobName}_oozie_status.txt    echo "Oozie job id not generated : XML didnt get generated properly"  >> ${LOG_DIR}/${jobName}_oozie_status.txt    rm -f ${LOG_DIR}/*${jobName}*    exit 1else    counter=0    while [ $counter -ne 1 ]    do    OozieStatus=`oozie job -oozie ${OOZIE_URL} -info ${oozieJobId} | grep "Status        :" | cut -d':' -f2 | sed "s/^[ ]*//"`    echo "${OozieStatus}" > ${LOG_DIR}/oozie_status_${jobName}.txt    chmod 775 ${LOG_DIR}/oozie_status_${jobName}.txt    if [[ $OozieStatus == 'SUCCEEDED'  ]]    then        counter=`expr $counter + 1`        echo "Job Status:${OozieStatus}"        rm -f ${LOG_DIR}/${jobName}_oozie_status.txt        echo "Subject : Workflow status of $oozieJobId is ${OozieStatus}" > ${LOG_DIR}/${jobName}_oozie_status.txt        chmod 775 ${LOG_DIR}/${jobName}_oozie_status.txt        oozie job  -oozie ${OOZIE_URL} -info ${oozieJobId} >> ${LOG_DIR}/${jobName}_oozie_status.txt        chmod 775 ${LOG_DIR}/${jobName}_oozie_status.txt        rm -f ${LOG_DIR}/oozie_status_${jobName}.txt        rm -f ${LOG_DIR}/${jobName}_oozie_status.txt        exit 0    elif [[ $OozieStatus == 'FAILED'  ]] || [[ $OozieStatus == 'KILLED'  ]] || [[ $OozieStatus == 'SUSPENDED'  ]]    then        rm -f ${LOG_DIR}/${jobName}_oozie_status.txt        echo "Subject : Workflow status of $oozieJobId is ${OozieStatus}" > ${LOG_DIR}/${jobName}_oozie_status.txt        chmod 775 ${LOG_DIR}/${jobName}_oozie_status.txt        oozie job  -oozie ${OOZIE_URL} -info ${oozieJobId} >> ${LOG_DIR}/${jobName}_oozie_status.txt        echo "oozieJobId=${oozieJobId}" > ${LOG_DIR}/oozie_status_${jobName}.txt        chmod 755 ${LOG_DIR}/oozie_status_${jobName}.txt        exit 1    else        sleep 30        echo "Job Status:${OozieStatus}"        continue    fi    donefi