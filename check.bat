ECHO off
REM  Alternative: command && success action || failure action
IF EXIST "ocpn-plugins.xml" ( 
DEL ocpn-plugins-bak.xml 
ECHO ocpn-plugins.xml found and ocpn-plugins-bak.xml removed 
COPY ocpn-plugins.xml ocpn-plugins-bak.xml
ECHO ocpn-plugins.xml file copied to ocpn-plugins-bak.xml. 
ECHO Generating new ocpn-plugins.xml  
python tools/ocpn-metadata generate --userdir metadata --destfile ocpn-plugins.xml --force --verbose
ECHO Checking all metadata urls.
python tools/check-metadata-urls
DIR
) ELSE (
ECHO ocpn-plugins.xml not found. 
ECHO Generating new ocpn-plugins.xml
python tools/ocpn-metadata generate --userdir metadata --destfile ocpn-plugins.xml --verbose
ECHO Checking all metadata urls.
python tools/check-metadata-urls
DIR
)
::   ECHO Check all metadata urls?
::   ECHO 1 Yes
::   ECHO 2 No
::   SET /p web=Type option:
::   IF "%web%"=="1" goto check
::   IF "%web%"=="2" goto end
::   :check
