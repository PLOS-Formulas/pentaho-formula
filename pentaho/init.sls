{%- from "pentaho/envmap.jinja" import env_config as config with context %}
{%- set env_props = salt.pillar.get('environment:' + salt.grains.get('environment')) %}
{%- set environment = salt.grains.get('environment') %}
{%- set version = config['current_version'] %}
{%- set install_loc = config['install_loc'] %}
{%- set s3_loc = 's3://salt-prod/pentaho' %}
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
    - source: salt://pentaho/conf/opt/pentaho
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
unzip_pdd_plugin:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['pdd-plugin.zip']['unzip_loc'] }}  
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pdd-plugin.zip']['source_loc'] }} 
    - source_hash: {{ config['versions'][version]['pdd-plugin.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

unzip_pir_plugin:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['pir-plugin.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pir-plugin.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pir-plugin.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

unzip_paz_plugin:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['paz-plugin.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['paz-plugin.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['paz-plugin.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

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

unzip_solutions:
  archive.extracted:
    - name: {{ install_loc }}/{{ config['versions'][version]['pentaho-solutions.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pentaho-solutions.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pentaho-solutions.zip']['hash'] }}
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
      - file: {{ install_loc }}/conf/*

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
