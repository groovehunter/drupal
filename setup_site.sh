#!/bin/bash

passwd=`cat /home/konnertz/.drush/dru_secrets`

## CUSTOMIZE next lines
distro_name="politeia"
site_base="polis"
site_tld="utopiaspora.net"
#site_tld="local.lan"
site_prod="polis.$site_tld"
## END 

usage() {
  echo "USAGE: `basename $0` <site:dev|staging|prod>"
  exit
}

# search string is the first argument and the rest are the array elements
contains() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}


avail=("dev" "staging" "prod")
if contains "$1" "${avail[@]}"
then 
  echo "$1 is defined."
else
  echo "ERROR: $1 is not defined as site"
  usage
fi

if test "$1" == "prod"
then
  SITE=$site_prod
  DB="prod"
else
  SITE="$site_base-$1.$site_tld"
  DB="$1"
fi

echo "Setting up $SITE \n"


DRUPAL_ROOT=/var/www/vhosts/$SITE
INSTALL_DIR=$DRUPAL_ROOT/sites/default
export DRUPAL_ROOT
export INSTALL_DIR

if ! [[ -d $DRUPAL_ROOT ]]
then
    mkdir $DRUPAL_ROOT;
fi
echo "change to directory $DRUPAL_ROOT"
cd $DRUPAL_ROOT


echo "delete all below $DRUPAL_ROOT"
echo "superuser password needed!"
sudo rm * -r 

echo "\nsetup drupal site according to drush makefile..."
#url_gitweb="http://mygitwebsite.com/$distro_name.git;a=blob_plain;f=build-$distro_name.make;hb=HEAD" -y
#url_github="https://github.com/groovehunter/$distro_name/blob/master/build-$distro_name.make"
url_github="https://raw.github.com/groovehunter/$distro_name/master/build-$distro_name.make"
echo "drush make $url_github"
drush make "$url_github" -y

if test "$?" != 0
then
  echo "drush make FAILED. Exiting..."
  exit
fi
echo $?
#exit

echo "\ninstall drupal instance..."
#drush si $distro_name --db-url="mysql://drupal:$passwd@localhost/drupal_$site_name_$DB" -y
drush si $distro_name --db-url="mysql://drupal:$passwd@localhost/drupal_$site_name_$DB" -y
# OK?

echo "change permissions in install folder"
sudo chgrp www-data $INSTALL_DIR/files -R
sudo chmod g+w $INSTALL_DIR/files -R

### general drupal tweaks
./setup_drupal_general.sh

echo "change directory to custom module folder"
cd $DRUPAL_ROOT/profiles/$distro_name/modules
mkdir $site_name
cd $site_name


echo "get custom modules via git clone..."
git clone "https://github.com/groovehunter/openspirit_basic_features.git"

echo "change directory to install folder $INSTALL_DIR"
cd $INSTALL_DIR


### user, roles, ldap
echo "drush create roles..."
drush scr $DRUPAL_ROOT/profiles/$distro_name/modules/distro_name/config/create_roles.script drupal_roles_dev create

cd $DRUPAL_ROOT/profiles/$site_distro/modules/contrib
# clone l10n_update dev version
# git clone --recursive --branch 7.x-1.x http://git.drupal.org/project/l10n_update.git
# clone taxonomy_csv with fixed issue https://drupal.org/node/1475952
echo "change directory to install folder $INSTALL_DIR"
cd $INSTALL_DIR



### sonstiges
echo "setting site variables..."
drush vset site_name "$site_name"
drush vset site_default_country de
drush vset configurable_timezones 0
drush vset date_default_timezone "Europe/Berlin"
drush vset user_default_timezone: "0"
drush vset date_first_day "1"

if [ $http_proxy ]
then
    drush vset proxy_server "$http_proxy"
    #drush vset proxy_port ""
fi



# other vars
echo "setting further variables..."
drush vset date_format_short "d.m.Y"

drush en l10n_update -y
drush language-add de
drush language-default de
drush l10n-update


echo "FINISHED setup script. Check above for errors!"



