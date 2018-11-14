{%- from "pentaho/envmap.jinja" import env_config as config with context %}
{%- set env_props = salt.pillar.get('environment:' + salt.grains.get('environment')) %}
{%- set environment = salt.grains.get('environment') %}
{%- set version = config['current_version'] %}
{%- set install_loc = config['install_loc'] %}
{%- set s3_loc = 's3://salt-prod/pentaho' %}
{%- set mysql_host = 'config['mysql_host'] %}
{%- set mysql_hibernate_user = config['hibernate']['mysql_user'] %}
{%- set mysql_hibernate_host = mysql_host %}
{%- from 'lib/tomcat.sls' import tomcat_user %}
{{ tomcat_user('pentaho') }}

include:
  - tomcat8-libs
  - prometheus.exporters.jmx

conf_file_init_default:
  file.managed:
    - template: jinja
    - name: /etc/default/pentaho
    - source: salt://pentaho/conf/etc/default/pentaho
    - context:
        java_loc: "/usr/lib/jvm/java-8-oracle"
        j_opts: |
          {{ config['j_opts'] }}

dir_pentaho_dot:
  file.directory:
    - name: {{ install_loc }}/.pentaho
    - makdirs: true
    - user: pentaho
    - group: pentaho

dir_pentaho_server:
  file.directory:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/
    - makedirs: true
    - user: pentaho
    - group: pentaho

dir_opt_pentaho:
  file.recurse:
    - template: jinja
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/tomcat/
    - source: salt://pentaho/conf/opt/pentaho/tomcat
    - include_empty: True
    - user: pentaho
    - group: pentaho
    - dir_mode: 0755 
    - file_mode: 0744 
    - clean: False
    - replace: False # this means any changes are not replaced! you have to delete the file for salt to recreate the file
    - require:
      - file: dir_pentaho_server

#TODO: these unzips should be a simple for loop with .iteritems()
unzip_solutions:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['pentaho-solutions.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pentaho-solutions.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pentaho-solutions.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

unzip_pdd_plugin
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['pdd-plugin.zip']['unzip_loc'] }}  
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pdd-plugin.zip']['source_loc'] }} 
    - source_hash: {{ config['versions'][version]['pdd-plugin.zip']['hash'] }}
    - enforce_toplevel: False
    - user: pentaho
    - group: pentaho
    - archive_format: zip
    - require:
      - archive: unzip_solutions

unzip_pir_plugin:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['pir-plugin.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pir-plugin.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pir-plugin.zip']['hash'] }}
    - enforce_toplevel: False
    - user: pentaho
    - group: pentaho
    - archive_format: zip
    - require:
      - archive: unzip_solutions

unzip_paz_plugin:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['paz-plugin.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['paz-plugin.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['paz-plugin.zip']['hash'] }}
    - enforce_toplevel: False
    - user: pentaho
    - group: pentaho
    - archive_format: zip
    - require:
      - archive: unzip_solutions

unzip_license_installer:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['license-installer.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['license-installer.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['license-installer.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

unzip_jdbc_utility:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['jdbc-distribution-utility.zip']['unzip_loc'] }}
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['jdbc-distribution-utility.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['jdbc-distribution-utility.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

unzip_data:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['pentaho-data.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pentaho-data.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pentaho-data.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

symlink_current_pentaho_version:
  file.symlink:
    - name: {{ install_loc }}/pentaho
    - target: {{ install_loc }}/{{ version }}
    - user: pentaho
    - group: pentaho

restart_for_pentaho_configs:
  cmd.run:
    - name: service pentaho restart
    - onchanges:
      - file: {{ install_loc }}/pentaho/server/pentaho-server/tomcat/conf/*

#apparently pentaho needs xvfb to generate charts and stuff 
pentaho_required_xvfb:
  pkg.latest:
    - name: xvfb

# configuration changes for mysql backing
quartz_db_mysql_jobstore_driver:
  file.line:
    - name: {{ install_loc }}/pentaho/server/pentaho-server/pentaho-solutions/system/quartz/quartz.properties
    - content: org.quartz.jobStore.driverDelegateClass = org.quartz.impl.jdbcjobstore.StdJDBCDelegate
    - match: org.quartz.jobStore.driverDelegateClass = org.quartz.impl.jdbcjobstore.PostgreSQLDelegate
    - mode: replace
    - user: pentaho
    - group: pentaho
    - file_mode: 664 

hibernate_specify_db_mysql_cnf_file:
  file.line:
    - name: {{ install_loc }}/pentaho/server/pentaho-server/pentaho-solutions/system/hibernate/hibernate-settings.xml
    - content: <config-file>system/hibernate/mysql5.hibernate.cfg.xml</config-file>
    - match: <config-file>system/hibernate/postgresql.hibernate.cfg.xml</config-file>
    - mode: replace
    - indent: True
    - user: pentaho
    - group: pentaho
    - file_mode: 644 

hibernate_db_mysql_cnf_file:
  file.managed:
    - name: {{ install_loc }}/pentaho/server/pentaho-server/pentaho-solutions/system/hibernate/mysql5.hibernate.cfg.xml
    - template: jinja
    - source: salt://pentaho/server/pentaho-server/pentaho-solutsions/system/hibernate/mysql5.hibernate.cfg.xml
    - context: 
        mysql_hibernate_host: {{ mysql_hibernate_host }}
        mysql_hibernate_user: {{ mysql_hibernate_user }}
        mysql_hibernate_pass: {{ salt.pillar.get('secrets:pentaho:mysql:hibernate:password') }}

#pentaho_jmx_exporter:
#  plos_consul.advertise:
#    - name: tomcat_jmx_exporter
#    - port: 7071
#    - tags:
#      - {{ environment }}
#      - cluster=pentaho
#    - checks:
#      - tcp: {{ grains['fqdn'] }}:7071
#        interval: 10s
