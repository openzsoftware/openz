# OpenZ - Open Source ERP-System

OpenZ is an open source Enterprise Resource Planning System forked from Openbravo ERP, Version 2.50.15979 MP11. Visit [https://openz.de/](https://openz.de/) for more information.

This repository is read-only and active development is done in a privat repository. Feel free to send contributions to [info@openz.de](mailto:info@openz.de).

A ready to use system is available as a VirtualBox image at [https://sourceforge.net/projects/openz/files/VirtualAppliance/](https://sourceforge.net/projects/openz/files/VirtualAppliance/).

## Installation
A full installation guide in German is available at [https://openz.de/handbuch/openz-entwicklung/wptsaentwicklungsugbgb/](https://openz.de/handbuch/openz-entwicklung/wptsaentwicklungsugbgb/).


### Requirements

You will need to download and start the VirtualBox image from [https://sourceforge.net/projects/openz/files/VirtualAppliance/](https://sourceforge.net/projects/openz/files/VirtualAppliance/) to get a test database. Use the *.ova with the matching version number. 
This is only needed once. The test database is located at ```/var/lib/postgresql/testcompany.sql```. Additionally an empty database without test data is located at ```/home/zisoft/openz/openz.sql```.


- clone the repository
- install ```postgresql-11``` from the Postgres Repository [https://www.postgresql.org/download/linux/ubuntu/](https://www.postgresql.org/download/linux/ubuntu/)
- install ```postgresql-contrib```, ```openjdk-11-jdk``` and ```ant```
- install and setup Apache Tomcat 9:

   download from [https://tomcat.apache.org/download-90.cgi](https://tomcat.apache.org/download-90.cgi)
   
   extract to ```/home/*username*/tomcat```
   
   in ```/tomcat/bin/catalina.sh``` change line 295 to ```UMASK="0022″``` 

   in ```/tomcat/conf/tomcat-users.xml``` at line 55 add ```<role rolename="manager-gui"/> <role rolename="manager"/>   <role rolename="admin"/>   <user password="a" roles="admin,manager,manager-gui" username="admin"/>```
- setup postresql (create role and import database)

   ```sudo su postgres```
   
   ```psql```
   
   ```CREATE ROLE tad; alter role tad with password 'tad'; alter role tad login; alter role tad SUPERUSER;```
      
   reboot computer
   
   ```sudo su postgres```
   
   ```psql```
   
   ```create database openz;```
   
   ```\q```
   
   ```psql openz < /*path to*/testcompany.sql```
- set environment variables
  
  add the following variables to ```/etc/environment```
   
   ```JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/"```
  
   ```CATALINA_HOME="/*path to*/tomcat/"```
   
   ```CATALINA_BASE="/*path to*/tomcat/"```
   
   ```OPENZ_GITPT="/tmp/"```
   
   ```OPENZ_GITOSS="/*path to*/openz/"```

   reboot computer
   
### Compile source code with ant

In the ```/openz/``` directory run ```ant core.lib && ant trl.lib && ant wad.lib && ant compile.complete && ant build.deploy```. From now on only ```ant compile.complete && ant build.deploy``` is needed for compilation.

### Setup Eclipse

- install Eclipse IDE for Enterprise Java and Web Developers
- setup the project and tomcat

   Window -> Preferences -> Java -> installed JRE's 
   
   check if java-11-openjdk-amd64 is selected
   
   Window -> Preferences -> Server -> Runtime Environment 
   
   add a new Apache Tomcat v9.0 server and set the installation directory to ```/*path to*/tomcat```
   
   File -> New -> Dynamic Web Project
   
   project location is the openz repository
   
   Target Runtime is Apache Tomcat v9.0
   
   Dynamic web module version is 4.0
   
   Configuration is Default Configuration for Apache Tomcat v9.0
   
   Finish
   
   Project -> uncheck Build automatically 
- set build path

   Window -> Preferences -> Java -> Build Path 
   
   User Libraries -> New 
   
   Create new Library with the name "OpenZ"
   
   Add External JARs
   
   go to the directory ```/openz/lib/runtime```
   
   select everything in this folder and confirm
- import of the source files

   right click a directory -> Build Path -> Use as Source Folder
   
   in the directory ```/openz/modules/``` add every subfolder named ```src``` (i.e. ```/openz/modules/*/src```)
   
   additionally add the directorys ```/openz/src```, ```/openz/srcAD```, ```/openz/src-gen```, ```/openz/src-core/src```, ```/openz/build/javasqlc/src``` and ```build/javasqlc/srcAD```
- validation off/build on

   Window -> Preferences -> Validation -> check Suspend all Validators
   
   Project -> Properties -> Java Build Path -> Libraries -> Add Library -> User Library -> select openz
   
   Project -> Properties -> Project Facets -> set Java to 1.8
   
   Project -> Properties -> Project Facets -> set Dynamic Web Module to 3.1
   
   Project -> check Build automatically
- setup Tomcat server

   below the editing window
   
   Servers -> click to add new server
   
   select Tomcat v9.0 Server and confirm
   
   double click created server
   
   Publishing -> check Never publish automatically
   
   Server Location -> check Use Tomcat installation
   
   Timeouts -> set Start to 60
   
   Timeouts -> set Stop to 30
   
   save the changes
- Jasper Studio

   Help -> Eclipse Marketplace
   
   search for ```Jaspersoft Studio``` and install
   
   Window -> Preferences -> Jaspersoft Studio -> Compatibility
   
   set Version to JasperReport to 6.1.1
   
## Start OpenZ

- start Eclipse
- right click on the created server
- start
- after the server is started OpenZ is available at [http://localhost:8080/openz/security/Menu.html](http://localhost:8080/openz/security/Menu.html)
- login as user with service/service or as developer with openz/openz
