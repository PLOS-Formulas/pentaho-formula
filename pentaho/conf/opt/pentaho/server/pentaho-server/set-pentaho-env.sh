#!/bin/sh
#
#  HITACHI VANTARA PROPRIETARY AND CONFIDENTIAL
# 
#  Copyright 2002 - 2018 Hitachi Vantara. All rights reserved.
# 
#  NOTICE: All information including source code contained herein is, and
#  remains the sole property of Hitachi Vantara and its licensors. The intellectual
#  and technical concepts contained herein are proprietary and confidential
#  to, and are trade secrets of Hitachi Vantara and may be covered by U.S. and foreign
#  patents, or patents in process, and are protected by trade secret and
#  copyright laws. The receipt or possession of this source code and/or related
#  information does not convey or imply any rights to reproduce, disclose or
#  distribute its contents, or to manufacture, use, or sell anything that it
#  may describe, in whole or in part. Any reproduction, modification, distribution,
#  or public display of this information without the express written authorization
#  from Hitachi Vantara is strictly prohibited and in violation of applicable laws and
#  international treaties. Access to the source code contained herein is strictly
#  prohibited to anyone except those individuals and entities who have executed
#  confidentiality and non-disclosure agreements or other agreements with Hitachi Vantara,
#  explicitly covering such access.
# 
# -----------------------------------------------------------------------------
# Finds a suitable Java
#
# Looks in well-known locations to find a suitable Java then sets two 
# environment variables for use in other script files. The two environment
# variables are:
# 
# * _PENTAHO_JAVA_HOME - absolute path to Java home
# * _PENTAHO_JAVA - absolute path to Java launcher (e.g. java)
# 
# The order of the search is as follows:
#
# 1. argument #1 - path to Java home
# 2. environment variable PENTAHO_JAVA_HOME - path to Java home
# 3. jre folder at current folder level
# 4. java folder at current folder level
# 5. jre folder one level up
# 6 java folder one level up
# 7. jre folder two levels up
# 8. java folder two levels up
# 9. environment variable JAVA_HOME - path to Java home
# 10. environment variable JRE_HOME - path to Java home
# 
# If a suitable Java is found at one of these locations, then 
# _PENTAHO_JAVA_HOME is set to that location and _PENTAHO_JAVA is set to the 
# absolute path of the Java launcher at that location. If none of these 
# locations are suitable, then _PENTAHO_JAVA_HOME is set to empty string and 
# _PENTAHO_JAVA is set to java.
# 
# Finally, there is one final optional environment variable: PENTAHO_JAVA.
# If set, this value is used in the construction of _PENTAHO_JAVA. If not 
# set, then the value java is used. 
#
# START HITACHI VANTARA LICENSE
# To search for the pentaho license, this script will look into the current
# for .installedLicenses.xml, one folder up and two folder up. If file is
# found in any of these location PENTAHO_INSTALLED_LICENSE_PATH is set to that
# path including the file name
# END HITACHI VANTARA LICENSE

setPentahoEnv() {
  DIR_REL=`dirname $0`
  cd $DIR_REL
  DIR=`pwd`
  #cd -
  
  if [ -n "$PENTAHO_JAVA" ]; then
    __LAUNCHER="$PENTAHO_JAVA"
  else
    __LAUNCHER="java"
  fi
  if [ -n "$1" ] && [ -d "$1" ] && [ -x "$1"/bin/$__LAUNCHER ]; then
    echo "DEBUG: Using value ($1) from calling script"
    _PENTAHO_JAVA_HOME="$1"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -n "$PENTAHO_JAVA_HOME" ]; then
    echo "DEBUG: Using PENTAHO_JAVA_HOME"
    _PENTAHO_JAVA_HOME="$PENTAHO_JAVA_HOME"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -x "$DIR/jre/bin/$__LAUNCHER" ]; then
    echo DEBUG: Found JRE at the current folder
    _PENTAHO_JAVA_HOME="$DIR/jre"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -x "$DIR/java/bin/$__LAUNCHER" ]; then
    echo DEBUG: Found JAVA at the current folder
    _PENTAHO_JAVA_HOME="$DIR/java"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -x "$DIR/../jre/bin/$__LAUNCHER" ]; then
    echo DEBUG: Found JRE one folder up
    _PENTAHO_JAVA_HOME="$DIR/../jre"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -x "$DIR/../java/bin/$__LAUNCHER" ]; then
    echo DEBUG: Found JAVA one folder up
    _PENTAHO_JAVA_HOME="$DIR/../java"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -x "$DIR/../../jre/bin/$__LAUNCHER" ]; then
    echo DEBUG: Found JRE two folders up
    _PENTAHO_JAVA_HOME="$DIR/../../jre"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -x "$DIR/../../java/bin/$__LAUNCHER" ]; then
    echo DEBUG: Found JAVA two folders up
    _PENTAHO_JAVA_HOME="$DIR/../../java"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -n "$JAVA_HOME" ]; then
    echo "DEBUG: Using JAVA_HOME"
    _PENTAHO_JAVA_HOME="$JAVA_HOME"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  elif [ -n "$JRE_HOME" ]; then
    echo "DEBUG: Using JRE_HOME"
    _PENTAHO_JAVA_HOME="$JRE_HOME"
    _PENTAHO_JAVA="$_PENTAHO_JAVA_HOME"/bin/$__LAUNCHER
  else
    echo "WARNING: Using java from path"
    _PENTAHO_JAVA_HOME=
    _PENTAHO_JAVA=$__LAUNCHER
  fi
# START HITACHI VANTARA LICENSE
  if [ -z "$PENTAHO_INSTALLED_LICENSE_PATH" ]; then
    if [ -f "$DIR/.installedLicenses.xml" ]; then
      echo "DEBUG: Found Pentaho License at the current folder"
      PENTAHO_INSTALLED_LICENSE_PATH="$DIR/.installedLicenses.xml"
    elif [ -f "$DIR/../.installedLicenses.xml" ]; then
      echo "DEBUG: Found Pentaho License one folder up"
      PENTAHO_INSTALLED_LICENSE_PATH="$DIR/../.installedLicenses.xml"
    elif [ -f "$DIR/../../.installedLicenses.xml" ]; then
      echo "DEBUG: Found Pentaho License two folders up"
      PENTAHO_INSTALLED_LICENSE_PATH="$DIR/../../.installedLicenses.xml"
    fi
  fi  
# END HITACHI VANTARA LICENSE
  echo "DEBUG: _PENTAHO_JAVA_HOME=$_PENTAHO_JAVA_HOME"
  echo "DEBUG: _PENTAHO_JAVA=$_PENTAHO_JAVA"
# START HITACHI VANTARA LICENSE
  echo "DEBUG: PENTAHO_INSTALLED_LICENSE_PATH=$PENTAHO_INSTALLED_LICENSE_PATH"
# END HITACHI VANTARA LICENSE
}
