{%- from "pentaho/envmap.jinja" import env_config as config with context %}
{%- set environment = salt.grains.get('environment') %}
{%- set mysql_hibernate_user = config['hibernate']['mysql_user'] %}
{%- set mysql_jcr_user = config['jackrabbit']['mysql_user'] %}

include:
  - percona.common
  - common.repos

{% from 'lib/network.sls' import bind_ip0 with context %}
{% if environment == 'vagrant' %}
{% set mysql_ip = '127.0.0.1' %}
{% else %}
{% set mysql_ip = bind_ip0().rsplit('.', 3)[0] + '.%' %}
{% endif %}



# replacement instead of running the create_jcr_mysql.sql (https://help.pentaho.com/Documentation/8.1/Setup/Installation/Manual/MySQL_Repository)
jcr_db:
  mysql_database.present:
    - name: jackrabbit
  mysql_user.present:
    - name: '{{ mysql_jcr_user }}'
    - host: {{ mysql_ip }}
    - password: {{ pillar['secrets']['pentaho']['jcr']['mysql']['password'] }}
  mysql_grants.present:
    - database: jackrabbit.*
    - grant: ALL PRIVILEGES
    - host: {{ mysql_ip }}
    - user: {{ mysql_jcr_user }}

# replacement instead of running the create_repository_mysql.sql (https://help.pentaho.com/Documentation/8.1/Setup/Installation/Manual/MySQL_Repository)
repository_db:
  mysql_database.present:
    - name: hibernate
  mysql_user.present:
    - name: '{{ mysql_hibernate_user }}'
    - host: {{ mysql_ip }}
    - password: {{ pillar['secrets']['pentaho']['hibernate']['mysql']['password'] }}
  mysql_grants.present:
    - database: quartz.*
    - grant: ALL PRIVILEGES
    - host: {{ mysql_ip }}
    - user: {{ mysql_hibernate_user }}

# running the non table creation parts from create_quartz_mysql.sql (https://help.pentaho.com/Documentation/8.1/Setup/Installation/Manual/MySQL_Repository)
quartz_db:
  mysql_database.present:
    - name: quartz
  mysql_user.present:
    - name: 'pentaho_user'
    - host: {{ mysql_ip }}
    - password: {{ pillar['secrets']['pentaho']['pentaho_user']['mysql']['password'] }}
  mysql_grants.present:
    - database: quartz.*
    - grant: ALL PRIVILEGES
    - host: {{ mysql_ip }}
    - user: pentaho_user

quartz_hib_grant:
  mysql_grants.present:
    - database: quartz.*
    - grant: ALL PRIVILEGES
    - host: {{ mysql_ip }}
    - user: {{ mysql_hibernate_user }}

# running the table creations for quartz database
mk_QRTZ5_JOB_DETAILS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_JOB_DETAILS.frm
    - query: | 
       CREATE TABLE QRTZ5_JOB_DETAILS ( JOB_NAME  VARCHAR(200) NOT NULL, JOB_GROUP VARCHAR(200) NOT NULL, DESCRIPTION VARCHAR(250) NULL, JOB_CLASS_NAME   VARCHAR(250) NOT NULL, IS_DURABLE VARCHAR(1) NOT NULL, IS_VOLATILE VARCHAR(1) NOT NULL, IS_STATEFUL VARCHAR(1) NOT NULL, REQUESTS_RECOVERY VARCHAR(1) NOT NULL, JOB_DATA BLOB NULL, PRIMARY KEY (JOB_NAME,JOB_GROUP) );

mk_QRTZ5_JOB_LISTENERS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_JOB_LISTENERS.frm
    - query: | 
       CREATE TABLE QRTZ5_JOB_LISTENERS( JOB_NAME  VARCHAR(200) NOT NULL, JOB_GROUP VARCHAR(200) NOT NULL, JOB_LISTENER VARCHAR(200) NOT NULL, PRIMARY KEY (JOB_NAME,JOB_GROUP,JOB_LISTENER), FOREIGN KEY (JOB_NAME,JOB_GROUP) REFERENCES QRTZ5_JOB_DETAILS(JOB_NAME,JOB_GROUP));

mk_QRTZ5_TRIGGERS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_TRIGGERS.frm
    - query: | 
       CREATE TABLE QRTZ5_TRIGGERS ( TRIGGER_NAME VARCHAR(200) NOT NULL, TRIGGER_GROUP VARCHAR(200) NOT NULL, JOB_NAME VARCHAR(200) NOT NULL, JOB_GROUP VARCHAR(200) NOT NULL, IS_VOLATILE VARCHAR(1) NOT NULL, DESCRIPTION VARCHAR(250) NULL, NEXT_FIRE_TIME BIGINT(13) NULL, PREV_FIRE_TIME BIGINT(13) NULL, PRIORITY INTEGER NULL, TRIGGER_STATE VARCHAR(16) NOT NULL, TRIGGER_TYPE VARCHAR(8) NOT NULL, START_TIME BIGINT(13) NOT NULL, END_TIME BIGINT(13) NULL, CALENDAR_NAME VARCHAR(200) NULL, MISFIRE_INSTR SMALLINT(2) NULL, JOB_DATA BLOB NULL, PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP), FOREIGN KEY (JOB_NAME,JOB_GROUP) REFERENCES QRTZ5_JOB_DETAILS(JOB_NAME,JOB_GROUP));
 
mk_QRTZ5_SIMPLE_TRIGGERS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_SIMPLE_TRIGGERS.frm
    - query: | 
       CREATE TABLE QRTZ5_SIMPLE_TRIGGERS ( TRIGGER_NAME VARCHAR(200) NOT NULL, TRIGGER_GROUP VARCHAR(200) NOT NULL, REPEAT_COUNT BIGINT(7) NOT NULL, REPEAT_INTERVAL BIGINT(12) NOT NULL, TIMES_TRIGGERED BIGINT(10) NOT NULL, PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP), FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP));

mk_QRTZ5_CRON_TRIGGERS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_CRON_TRIGGERS.frm
    - query: | 
       CREATE TABLE QRTZ5_CRON_TRIGGERS ( TRIGGER_NAME VARCHAR(200) NOT NULL, TRIGGER_GROUP VARCHAR(200) NOT NULL, CRON_EXPRESSION VARCHAR(200) NOT NULL, TIME_ZONE_ID VARCHAR(80), PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP), FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP));

mk_QRTZ5_BLOB_TRIGGERS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_BLOB_TRIGGERS.frm
    - query: | 
       CREATE TABLE QRTZ5_BLOB_TRIGGERS ( TRIGGER_NAME VARCHAR(200) NOT NULL, TRIGGER_GROUP VARCHAR(200) NOT NULL, BLOB_DATA BLOB NULL, PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP), FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP));

mk_QRTZ5_TRIGGER_LISTENERS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_TRIGGER_LISTENERS.frm
    - query: | 
       CREATE TABLE QRTZ5_TRIGGER_LISTENERS ( TRIGGER_NAME VARCHAR(200) NOT NULL, TRIGGER_GROUP VARCHAR(200) NOT NULL, TRIGGER_LISTENER VARCHAR(200) NOT NULL, PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_LISTENER), FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP));

mk_QRTZ5_CALENDARS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_CALENDARS.frm
    - query: | 
       CREATE TABLE QRTZ5_CALENDARS ( CALENDAR_NAME VARCHAR(200) NOT NULL, CALENDAR BLOB NOT NULL, PRIMARY KEY (CALENDAR_NAME));

mk_QRTZ5_PAUSED_TRIGGER_GRPS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_PAUSED_TRIGGER_GRPS.frm
    - query: | 
       CREATE TABLE QRTZ5_PAUSED_TRIGGER_GRPS ( TRIGGER_GROUP VARCHAR(200) NOT NULL, PRIMARY KEY (TRIGGER_GROUP));

mk_QRTZ5_FIRED_TRIGGERS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_FIRED_TRIGGERS.frm
    - query: | 
       CREATE TABLE QRTZ5_FIRED_TRIGGERS ( ENTRY_ID VARCHAR(95) NOT NULL, TRIGGER_NAME VARCHAR(200) NOT NULL, TRIGGER_GROUP VARCHAR(200) NOT NULL, IS_VOLATILE VARCHAR(1) NOT NULL, INSTANCE_NAME VARCHAR(200) NOT NULL, FIRED_TIME BIGINT(13) NOT NULL, PRIORITY INTEGER NOT NULL, STATE VARCHAR(16) NOT NULL, JOB_NAME VARCHAR(200) NULL, JOB_GROUP VARCHAR(200) NULL, IS_STATEFUL VARCHAR(1) NULL, REQUESTS_RECOVERY VARCHAR(1) NULL, PRIMARY KEY (ENTRY_ID));

mk_QRTZ5_SCHEDULER_STATE_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_SCHEDULER_STATE.frm
    - query: | 
       CREATE TABLE QRTZ5_SCHEDULER_STATE ( INSTANCE_NAME VARCHAR(200) NOT NULL, LAST_CHECKIN_TIME BIGINT(13) NOT NULL, CHECKIN_INTERVAL BIGINT(13) NOT NULL, PRIMARY KEY (INSTANCE_NAME));

mk_QRTZ5_LOCKS_tbl:
  mysql_query.run:
    - database: quartz
    - unless: ls /var/lib/mysql/quartz/QRTZ5_LOCKS.frm
    - query: | 
       CREATE TABLE QRTZ5_LOCKS ( LOCK_NAME VARCHAR(40) NOT NULL, PRIMARY KEY (LOCK_NAME));INSERT INTO QRTZ5_LOCKS values('TRIGGER_ACCESS');INSERT INTO QRTZ5_LOCKS values('JOB_ACCESS');INSERT INTO QRTZ5_LOCKS values('CALENDAR_ACCESS');INSERT INTO QRTZ5_LOCKS values('STATE_ACCESS');INSERT INTO QRTZ5_LOCKS values('MISFIRE_ACCESS');commit;

# end table creations for quartz
