{% from "pentaho/map.jinja" import pentaho_props with context %}

{%- set env_props = salt.pillar.get('environment:' + salt.grains.get('environment')) %}
{%- set environment = salt.grains.get('environment') %}
{%- set version = config['current_version'] %}
{%- set source = config['versions'][version]['source'] %}
{%- set extract_dir = '/'.join([home, 'extract', version]) %}
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
          {{ pentaho_props.get('j_opts') }}

dir_pentaho_dot:
  file.directory:
    - name: /opt/pentaho/.pentaho
    - makdirs: true
    - user: pentaho
    - group: pentaho

dir_pentaho_server:
  file.directory:
    - name: /opt/pentaho/{{ version }}/server/pentaho-server/
    - makedirs: true
    - user: pentaho
    - group: pentaho

dir_opt_pentaho:
  file.recurse:
    - template: jinja
    - name: /opt/pentaho/{{ version }}/server/pentaho-server/tomcat/
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



restart_for_pentaho_configs:
  cmd.run:
    - name: service pentaho restart
    - onchanges:
      - file: /opt/plos/pentaho/conf/*

pentaho_jmx_exporter:
  plos_consul.advertise:
    - name: tomcat_jmx_exporter
    - port: 7071
    - tags:
      - {{ environment }}
      - cluster=pentaho
    - checks:
      - tcp: {{ grains['fqdn'] }}:7071
        interval: 10s
