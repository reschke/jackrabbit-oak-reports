#!/bin/bash

REPO=repo/jackrabbit-oak
USETAG=${TAG-trunk}
set -x
 
if [ ! -d repo ] ; then
  rm -rfv repo
  mkdir repo
  (cd repo && git clone git@github.com:apache/jackrabbit-oak.git)
fi

(cd $REPO && rm -rfv */target && git checkout trunk && mvn clean && git checkout . && git pull && git checkout $USETAG && mvn clean install -DskipTests && mvn dependency:tree && mvn dependency:tree > dependencies.txt && git log -n1 > version.txt)

echo "<root>" >> $$.xml
for i in $(find $REPO/*/target -name baseline.xml) ; do
  cat $i >> $$.xml
done
echo "</root>" >> $$.xml

xmllint --format $$.xml -o baseline.xml
rm -f $$.xml
 
mv $REPO/dependencies.txt .
mv $REPO/version.txt .

COMMENT=$(printf "%s - %s" $USETAG $(head -1 version.txt))

# no auto-commit
echo git commit -a -m "$COMMENT"
