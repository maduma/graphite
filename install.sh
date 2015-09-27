# local repository for tar files
LOCAL_REPO=$PWD/repo

# utilities
pkg install wget
pkg install unzip

# download tar file in the repo directory
# if you don't have access to internet,
# you may download manualy the files and put them in a local repository named 'repo'
#
# django-tagging-0.3.4.tar.gz
# txAMQP-0.6.2.tar.gz
# carbon-0.9.13.tar.gz
# graphite-web-0.9.13.tar.gz
# whisper-0.9.13.tar.gz
# elasticsearch-1.4.4.zip
# grafana-1.9.1.zip
#
if [ ! -d $LOCAL_REPO ]; then
	mkdir -p $LOCAL_REPO
	(cd $LOCAL_REPO && wget https://pypi.python.org/packages/source/d/django-tagging/django-tagging-0.3.4.tar.gz)
	(cd $LOCAL_REPO && wget https://pypi.python.org/packages/source/t/txAMQP/txAMQP-0.6.2.tar.gz)
	(cd $LOCAL_REPO && wget https://pypi.python.org/packages/source/c/carbon/carbon-0.9.13.tar.gz)
	(cd $LOCAL_REPO && wget https://pypi.python.org/packages/source/g/graphite-web/graphite-web-0.9.13.tar.gz)
	(cd $LOCAL_REPO && wget https://pypi.python.org/packages/source/w/whisper/whisper-0.9.13.tar.gz)
	(cd $LOCAL_REPO && wget http://grafanarel.s3.amazonaws.com/grafana-1.9.1.zip)
	(cd $LOCAL_REPO && wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.4.zip)
fi

# solaris packages
pkg install library/python-2/python-twisted
pkg install library/python/django
pkg install library/python-2/pycairo-26
pkg install web/server/apache-22
pkg install web/server/apache-22/module/apache-wsgi
pkg install library/python/python-memcached
pkg install service/memcached
pkg install database/mysql-51
pkg install library/python-2/python-mysql
pkg install system/font/xorg/xorg-core
pkg install netcat
pkg install pip
pkg install --accept jre

# pip packages
pip install -f $LOCAL_REPO django-tagging==0.3.4
pip install -f $LOCAL_REPO whisper==0.9.13
pip install -f $LOCAL_REPO carbon==0.9.13
pip install -f $LOCAL_REPO graphite-web==0.9.13

# install elasticsearch
unzip -qd /opt $LOCAL_REPO/elasticsearch-1.4.4.zip
mv /opt/elasticsearch-1.4.4 /opt/elasticsearch
svccfg import svc/elasticsearch.xml

# install grafana
unzip -qd /opt $LOCAL_REPO/grafana-1.9.1.zip
mv /opt/grafana-1.9.1 /opt/grafana

# data filesystems
zfs create -o mountpoint=none rpool/data

## mysql
zfs create -o mountpoint=/var/mysql/5.1/data rpool/data/mysql
chmod 700 /var/mysql/5.1/data
chown mysql:mysql /var/mysql/5.1/data

## elasticsearch
zfs create -o mountpoint=/opt/elasticsearch/data rpool/data/elasticsearch

## graphite
mv /opt/graphite/storage /tmp
zfs create -o mountpoint=/opt/graphite/storage rpool/data/graphite
mv /tmp/storage /opt/graphite
chown -R webservd:webservd /opt/graphite/storage

# config files

## graphite
TIMEZONE=`svcprop -p timezone/localtime svc:/system/timezone:default`
sed "s#__TIMEZONE__#$TIMEZONE#" config/local_settings.py > /opt/graphite/webapp/graphite/local_settings.py
cp config/app_settings.py /opt/graphite/webapp/graphite/app_settings.py # add django.contrib.staticfiles app for collecstatic
cp config/graphite.wsgi /opt/graphite/conf/graphite.wsgi
cp config/carbon.conf /opt/graphite/conf/carbon.conf
cp config/storage-schemas.conf /opt/graphite/conf/storage-schemas.conf

## grafana
cp config/config.js /opt/grafana/config.js

## apache
cp config/httpd.conf /etc/apache2/2.2/httpd.conf # listen on 80 and 8080 
cp config/elasticsearch-proxy.conf /etc/apache2/2.2/conf.d/elasticsearch-proxy.conf
cp config/graphite-proxy.conf /etc/apache2/2.2/conf.d/graphite-proxy.conf
cp config/graphite-vhost.conf /etc/apache2/2.2/conf.d/graphite-vhost.conf # port 8080
cp config/grafana-vhost.conf /etc/apache2/2.2/conf.d/grafana-vhost.conf # port 80

# start mysql
svcadm enable -s mysql:version_51

# wait mysql to be up and running (bug - svcadm return before mysql is up)
while ! echo "show databases" | mysql >/dev/null 2>&1; do sleep 1; done

# create mysql db and user
mysql <<EOF
create database graphite;
create user 'graphite'@'localhost' identified by 'graphite';
grant all privileges on graphite.* to 'graphite'@'localhost';
flush privileges;
EOF
 
# db initialisation
PYTHONPATH=/opt/graphite/webapp django-admin syncdb --noinput --settings=graphite.settings --noinput

# django static file
PYTHONPATH=/opt/graphite/webapp django-admin collectstatic --noinput --settings=graphite.settings

# start carbon - /opt/graphite/bin/carbon-cache.py start
svccfg import svc/graphite.xml
svcadm enable -s graphite-carbon

# start memcached
svcadm enable -s memcached

# start elasticsearch
svcadm enable -s elasticsearch

# start apache
svcadm enable -s apache22

# create services.txt file
cat > /root/services.txt <<EOF
svc:/application/database/mysql:version_51
svc:/maduma/elasticsearch:default
svc:/application/database/memcached:default
svc:/maduma/graphite-carbon:default
svc:/network/http:apache22
EOF
