#!/bin/bash

# setting, hardcoded
#ENTITY=projekt
#BUNDLE=projekt
ENTITY_TYPE=projekt
BUNDLE=pj_bundle
PJTYP=


pjdir="$HOME/ownCloud/projekte/Ztyp_$PJTYP/projekte"
fn="$pjdir/Projektverzeichnis.csv"


### START
first=`cat $fn | head -1`
#echo $first

# remove parantheses
first=`echo $first | sed 's/[()]//g'`
first=`echo $first | tr " " "_"`
#echo $first

# split on comma
arr=$(echo $first | tr "," "\n")

# some inits
mapping_file="$pjdir/mapping.php"
echo "" > $mapping_file
i=0
val=""

### loop all terms
for x in $arr
do
  y=${x,,}
  if [ "${1}" = 'del' ]; then
    echo "> deleting field [$x]"
    echo "drush efd field_$y"
    drush -y efd field_$y
  fi

  if [ "${1}" = "add" ]; then
    echo "> creating field [$x]"
    # id mit lower case first letter
    echo "drush efc field_$y,text,$x,text_textfield --bundle=$BUNDLE --entity=$ENTITY_TYPE"
    drush efc field_$y,text,$x,text_textfield --bundle=$BUNDLE --entity=$ENTITY_TYPE
  fi

  val="$val $i => array(          
          'source' => '$x',
          'target' => 'field_$y',
          'unique' => FALSE,
          'language' => 'und',
        )," 

  ((i=i+1))
 # echo $i 

done

feed_config="$pjdir/feed_config.php"
feed_config_templ="$pjdir/feed_config_templ.php"
feed_config_templ2="$pjdir/feed_config_templ2.php"
rm $feed_config
touch $feed_config
#  >> $mapping_file

#sed -i "s/%MAP%/${val}/" $feed_config_
cat $feed_config_templ > $feed_config
echo $val >> $feed_config
cat $feed_config_templ2 >> $feed_config

#sed -e "s/MAPPING/$val/g" $feed_config_templ > $feed_config
#echo $val | sed -e "s/%MAP%//" $feed_config_templ > $feed_config
#echo $val
echo "END"

