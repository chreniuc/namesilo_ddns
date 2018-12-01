#!/bin/bash
# Hreniuc Cristian-Alexandru - cristi@hreniuc.pw
# You will need xmllint installed.

tmpfile=$(mktemp /tmp/update_XXXXXX.xml)

function clean_step
{
    rm $tmpfile
    exit $1
}
# Modify these:
APIKEY="apikey"
DOMAIN="mydomain.tld"
# If you are using a subdomain, do add the point.
SUBDOMAIN="test" # Leave it empty if there is no subdomain(rrhost).
RRVALUE="A" # Default value is for IPV4, put "AAAA" for IPV6

# Do not modify!
# Do the request:
curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > $tmpfile

# Get ip from the response
RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()" $tmpfile`
if [ "$RESPONSE_CODE" != "300" ]; then
  # Something went wrong
  FAIL_REASON=`xmllint --xpath "//namesilo/reply/detail/text()" $tmpfile`
  echo "Something went wrong when trying to 'dnsListRecords': $RESPONSE_CODE : $FAIL_REASON"
  # Send mail. TODO
  clean_step 1
fi

HOST=$DOMAIN
# If we have a subdomain, create the complete host: SUBDOMAIN + DOMAIN
if [ "${#SUBDOMAIN}" != "0" ]; then
    HOST="$SUBDOMAIN.$DOMAIN"
fi

# This is the IP that you currently have. This will be used to update the one from the dns record.
CURRENT_IP=`xmllint --xpath "//namesilo/request/ip/text()" $tmpfile`
# The unique id of the record that we want to modify it.
RECORD_ID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '$HOST' and ../type/text() = '$RRVALUE']/text()" $tmpfile`
# The IP that is set.
IP_VALUE=`xmllint --xpath "//namesilo/reply/resource_record/value[../host/text() = '$HOST' and ../type/text() = '$RRVALUE']/text()" $tmpfile`
if [ "$CURRENT_IP" == "$IP_VALUE" ]; then
    # There is no need to update it. It didn't change.
    clean_step 0
fi

curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$RECORD_ID&rrhost=$SUBDOMAIN&rrvalue=$CURRENT_IP" > $tmpfile
RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()"  $tmpfile`
if [ "$RESPONSE_CODE" != "300" ]; then
  # Something went wrong
  FAIL_REASON=`xmllint --xpath "//namesilo/reply/detail/text()" $tmpfile`
  echo "Something went wrong when trying to 'dnsUpdateRecord': $RESPONSE_CODE : $FAIL_REASON"
  # Send mail. TODO
  clean_step 1
fi

echo "We successfully updated the DNS record."
clean_step 0
