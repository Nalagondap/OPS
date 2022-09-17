#! /bin/bash

CERTS_SCRIPT=certs.sh 
DOMAIN_FILE=ssldomains
SUBJECT=`date +%D`
#CHANNEL="mukesha2@cisco.com"
CHANNEL="npavanreddy267@gmail.com"
SENDER="npavanreddy267@gmail.com"
CONTENT="op.html"

red='\033[0;31m'
clr='\033[0m'

domains=`cat ssldomains`
nxdomains=()
workingdomains=()

for j in $domains
do
 response=`nslookup $j`
 ns_exit_status=`echo $?`
 echo "#####$j#######"
 echo "$response"
 echo "#####$j#######"

 NZ_RS=`nc -zv $j 443`
 NZ_ES=`echo $?`

 echo "####ns_exit_status: $ns_exit_status##########"
 echo "####NZ_ES: $NZ_ES##########"

 if [[ $response == *"server can't find $j: NXDOMAIN"* ]] || [[ $ns_exit_status -ne 0 ]] || [[ $NZ_ES -ne 0 ]] ;then
   echo "$j, Domain is not resolving the Server"
   nxdomains+=($j)
 else
   echo "$j, Domain is working"
   workingdomains+=($j)
 fi
done

echo "Printing Domains which are up:"
for value in "${workingdomains[@]}"
do
   echo $value 443 >>working_domains_file
done


echo "Printing Domains which are not up"
echo "${nxdomains[*]}" | xargs | sed -e 's/ /,/g'


if [[ ! -f "$CERTS_SCRIPT"  || ! -f $DOMAIN_FILE  ]];then
	echo "certs_script  is not exist Please create it..."
	exit 1;
fi


echo "calling certs-validity script to check the expiration day"
bash certs.sh -a -f working_domains_file >rawop
#sort -k5 rawop | awk '{print $1 "\t" $2 "\t" $3$4$5 "\t" $6}' >op
#sort -n -k6 rawop | awk '{print $1 "\t" $2 "\t" $3$4$5 "\t" $6}' >op

head -n 2 rawop > op
cat rawop | grep -v "Host" | awk '{print $1 "\t" $2 "\t" $3$4$5 "\t" $6}' | sort -n -k4 >> op


echo "###############################Notification Message################################################"
echo "<html>" >> op.html
echo "<body>" >> op.html
echo "<p>Hello Team, Please find the weekly Certificate Renewal Report & take Action Accordingly " >> op.html
echo "<br></br> " >>op.html
awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print "<h5><td>" $i"</td></h5>";print "</tr>"} END{print "</table>"}' op >>op.html

echo "<h5 style='color:red;'>  Note: Following Domains  are not resolvable may be their respective clusters are not UP </h5>" >>op.html
echo "<h4>${nxdomains[*]}</h4>" | xargs | sed -e 's/ /,/g' >>op.html


#mail -a "Content-type: text/html;"  -s "Weeky Certificate Renwal Reports - $SUBJECT" -a "From:$SENDER" $CHANNEL  < op.html
#mail -a  "Content-Type: text/html;"  -s "Weeky Certificate Renwal Reports - $SUBJECT"  $CHANNEL  < op.html
#sendmail -t  "Content-Type: text/html;"  -s "Weeky Certificate Renwal Reports - $SUBJECT"  $CHANNEL  < op.html
(
 echo "From: $SENDER"
 echo "Subject: Weeky Certificate Renwal Reports - $SUBJECT"
 echo "MIME-Version: 1.0"
 echo "Content-Type: text/html"
 echo "Content-Disposition: inline"
 cat $CONTENT
) | /usr/sbin/sendmail $CHANNEL

echo "empty the raw/html/working_domains_file file"
echo > op && echo > op.html && > working_domains_file && > rawop
