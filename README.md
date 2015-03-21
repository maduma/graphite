# Graphite and Grafana for solaris 11.2
This is a repice to install graphite, elasticsearch and grafana on solaris 11.2

- https://graphite.readthedocs.org/en
- https://www.elastic.co/products/elasticsearch
- http://grafana.org

## graphite version
- whisper 0.9.13
- carbon 0.9.13
- graphite-web 0.9.13

## middleware - version
- elasticsearch 1.4.4
- grafana 1.9.1
- mysql 5.1.37
- memcached  1.4.17
- apache 2.2.29
- mod_wsgi 3.3

## configuration
- carbon listen on 2003
- graphite listen on 8080
- elasticsearch listen on 9200
- apache reverse proxy /graphite to localhost:8080
- apache reverse proxy /elasticsearch to localhost:9200
- grafana service on port 80

## requirement
Solaris 11.2 group/system/solaris-minimal-server

## usage
    # pkg install git
    # git clone https://github.com/maduma/graphite.git
    # cd graphite
    # bash -x install.sh

see inline comment in the install.sh script for more information. Point your favorite browser to server name.
