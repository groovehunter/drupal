#!/bin/bash
# vom orig setup_site abgekupfert, sollte noch vereinfacht werden 
# ziel: keine distro sondern setup von dev sites von einer lieblings
# dev distro,m zb openspirit

### 
verbose="-v"
#verbose=""
nocache="--no-cache"
#nocache=""
### github

PWD=`pwd`
distro_name="openspirit"
export distro_name

github_user="groovehunter"
branch="d8"
url_github="https://raw.github.com/$github_user/$distro_name/$branch/build-$distro_name.make"
# local DB password, user="drupal"

### git local
url_local="file:///home/konnertz/git-test/$distro_name/build-$distro_name.make"
url=$url_local
### end url 
### END config section


# SETTINGS:
passwd=`cat ~/.drush/dru_secrets`
### custom config section
site_name=`basename $PWD`
echo "distro name: $distro_name"
site_base=$distro_name
site_prod=$site_base
site_tld=""

### github
# local DB password, user="drupal"

SITE="$site_base"
DB=$distro_name_$1

if $site_tld
then
  SITE="$SITE$site_tld"
fi

echo "Setting up $SITE \n"


DRUPAL_ROOT=`pwd`/$SITE
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

echo "drush make $nocache $url"
drush make $verbose $nocache "$url" -y

if test "$?" != 0
then
  echo "drush make FAILED. Exiting..."
  exit
fi
echo $?

#### DEV
exit
echo
echo "install drupal instance..."
#drush si $distro_name --db-url="mysql://drupal:$passwd@localhost/drupal_$site_name_$DB" -y
drush si $distro_name --db-url="mysql://drupal:$passwd@localhost/drupal_${site_name}_${DB}" -y
# OK?


echo "change permissions in install folder"
sudo chgrp www-data $INSTALL_DIR/ -R
sudo chmod g+w $INSTALL_DIR/ -R

### general drupal tweaks UNUSED, not sure if I keep that
# ./setup_drupal_general.sh

echo "change directory to custom module folder"
cd $DRUPAL_ROOT/profiles/$distro_name/modules
mkdir $site_name
cd $site_name


echo "get custom modules via git clone..."
#git clone "https://github.com/groovehunter/openspirit_basic_features.git"

echo "change directory to install folder $INSTALL_DIR"
cd $INSTALL_DIR

cd $DRUPAL_ROOT/profiles/$distro_name/modules/contrib
# clone l10n_update dev version
#git clone --recursive --branch 7.x-1.x http://git.drupal.org/project/l10n_update.git
# clone taxonomy_csv with fixed issue https://drupal.org/node/1475952
echo "change directory to install folder $INSTALL_DIR"
cd $INSTALL_DIR


### sonstiges
echo "setting site variables..."
#drush vset site_name "$site_name"
#drush vset site_default_country de
#drush vset configurable_timezones 0
#drush vset date_default_timezone "Europe/Berlin"
#drush vset user_default_timezone: "0"
#drush vset date_first_day "1"

### update notifications
#drush vset update_check_disabled 0
#drush vset update_check_frequency "7"
#drush vset update_notification_threshold "all"

### admin menu
#drush vset admin_menu_tweak_modules 1
#drush vset admin_menu_tweak_permissions 1



# other vars
echo "setting further variables..."
#drush vset date_format_short "d.m.Y"

drush en l10n_update -y
drush language-add de
drush language-default de
### outcomment, takes too long for setup script
#drush l10n-update

echo "call distro specific setup script"
echo "$DRUPAL_ROOT/profiles/$distro_name/setup_$distro_name.sh"
sh $DRUPAL_ROOT/profiles/$distro_name/setup_$distro_name.sh

### custom settings, ie. proxy
sh ~/drupal_custom/setup_site_custom.sh

echo "FINISHED setup script. Check above for errors!"

