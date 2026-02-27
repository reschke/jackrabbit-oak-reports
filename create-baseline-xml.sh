#!/bin/bash

REPO=repo/jackrabbit-oak
USETAG=${TAG-trunk}

set -x
 
if [ ! -d repo ] ; then
  rm -rfv repo
  mkdir repo
  (cd repo && git clone git@github.com:apache/jackrabbit-oak.git)
fi

(cd $REPO && rm -rfv */target && git checkout trunk && mvn clean && git checkout . && git pull && git checkout $USETAG && mvn clean install -DskipTests && mvn dependency:tree && mvn dependency:tree | fgrep -v SUCCESS | fgrep -v "Total time" | fgrep -v "Finished at" > dependencies.txt && git log -n1 > version.txt)

echo "<root>" >> $$.xml
for i in $(find $REPO/*/target -name baseline.xml) ; do
  cat $i | sed 's/ generatedOn="[^"]*"//g' | sed 's/ currentVersion="[^"]*"//g' | sed 's/ previousVersion="[^"]*"//g' >> $$.xml
done
echo "</root>" >> $$.xml

xmllint --format $$.xml -o baseline.xml
rm -f $$.xml
 
cat $REPO/dependencies.txt | sed -E 's/(apache\.jackrabbit\:[^0-9]*)([0-9]+(\.[0-9]+)+)/\1THIS/g' | fgrep -vi BUILDING | fgrep -v " from " | fgrep -v "Reactor" > dependencies.txt
mv $REPO/version.txt .

COMMENT=$(printf "%s - %s" $USETAG $(head -1 version.txt))

# no auto-commit
echo git commit -a -m "$COMMENT"
