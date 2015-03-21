This is a repice to install graphite elasticsearch and grafana on solaris 11.2

# graphite
whisper 0.9.13
carbon 0.9.13
graphite-web 0.9.13

# middleware
elasticsearch 1.4.4
grafana 1.9.1
mysql 5.1.37
memcached  1.4.17
apache 2.2.29
mod_wsgi 3.3

# configuration
graphite listen on 8080
elasticsearch on 9200
apache reverse proxy /graphite to localhost:8080
apache reverse proxy /elasticsearch to localhost:9200
apache docroot to /opt/grafana