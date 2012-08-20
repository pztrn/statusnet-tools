#!/bin/bash

HOST="localhost"
DB="changeme"
USER="changeme"
PASSWORD="changeme"

main() {
    set -e
    mysql --user=$USER --password=$PASSWORD --host=$HOST --database=$DB -e 'CREATE OR REPLACE VIEW vwGroupSuccess AS SELECT DISTINCT LOWER(SUBSTR(`content`,LOCATE("!",`content`)+1,LOCATE(" ",CONCAT(SUBSTR(`content`,LOCATE("!",`content`)+1)," "))-1)) "successful" FROM `notice` WHERE (`content` LIKE "%!%" OR `content` LIKE "!%") AND `rendered` LIKE CONCAT("%","nickname group\">",SUBSTR(`content`,LOCATE("!",`content`)+1,LOCATE(" ",CONCAT(SUBSTR(`content`,LOCATE("!",`content`)+1)," "))-1),"%") AND `profile_id` = 1 AND ISNULL( `repeat_of` ) AND LOWER(SUBSTR(`content`,LOCATE("!",`content`)+1,LOCATE(" ",CONCAT(SUBSTR(`content`,LOCATE("!",`content`)+1)," "))-1)) <> "";'
    
    if [ $? != 0 ]; then
        echo "Failed to create vwGroupSuccess view!"
    else
        echo "vwGroupSuccess created/updated"
    fi
    
    mysql --user=$USER --password=$PASSWORD --host=$HOST --database=$DB -e 'CREATE OR REPLACE VIEW vwGroupFailed AS SELECT DISTINCT LOWER(SUBSTR(`content`,LOCATE("!",`content`)+1,LOCATE(" ",CONCAT(SUBSTR(`content`,LOCATE("!",`content`)+1)," "))-1)) "unsuccessful" FROM `notice` WHERE (`content` LIKE "%!%" OR `content` LIKE "!%") AND `rendered` NOT LIKE CONCAT("%","nickname group\">",SUBSTR(`content`,LOCATE("!",`content`)+1,LOCATE(" ",CONCAT(SUBSTR(`content`,LOCATE("!",`content`)+1)," "))-1),"%") AND `profile_id` = 1 AND ISNULL( `repeat_of` ) AND LOWER(SUBSTR(`content`,LOCATE("!",`content`)+1,LOCATE(" ",CONCAT(SUBSTR(`content`,LOCATE("!",`content`)+1)," "))-1)) <> "";'
    
    if [ $? != 0 ]; then
        echo "Failed to create vwGroupFailed view!"
    else
        echo "vwGroupFailed created/updated"
    fi
    
    mysql --user=$USER --password=$PASSWORD --host=$HOST --database=$DB -e 'CREATE OR REPLACE VIEW vwGroupAccuracy AS SELECT `user_group`.`nickname` "groupnick" , `group_member`.`group_id` , `user_group`.`uri` "group_url" , CASE WHEN ISNULL(`linked`.`successful`) THEN "" ELSE "X" END "successful_group" , CASE WHEN ISNULL(`failed`.`unsuccessful`) THEN "" ELSE "X" END "failed_group" , CASE WHEN ISNULL(`group_alias`.`group_id`) THEN "" ELSE "X" END "has_alias" , `user_group`.`created` "group_db_entry" , `group_member`.`created` "joined_group" FROM `group_member` INNER JOIN `user_group` ON `group_member`.`group_id` = `user_group`.`id` LEFT JOIN `vwGroupSuccess` `linked` ON LOWER(`user_group`.`nickname`) = `linked`.`successful` LEFT JOIN `vwGroupFailed` `failed` ON LOWER(`user_group`.`nickname`) = `failed`.`unsuccessful` LEFT JOIN `group_alias` ON `group_member`.`group_id` = `group_alias`.`group_id` WHERE `group_member`.`profile_id` = 1 ORDER BY `groupnick`;'
    
    if [ $? != 0 ]; then
        echo "Failed to create vwGroupAccuracy view!"
    else
        echo "vwGroupAccuracy created/updated"
    fi
    
    mysql --user=$USER --password=$PASSWORD --host=$HOST --database=$DB -e 'INSERT INTO `group_alias` SELECT `unsuccessful` "alias" , `id` "group_id" , now() "modified" FROM `vwGroupFailed` INNER JOIN `user_group` ON `unsuccessful` = `nickname` LEFT JOIN `group_alias` ON `unsuccessful` = `alias` WHERE ISNULL(`group_alias`.`alias`);'
    
    if [ $? != 0 ]; then
        echo "Failed to add group aliases!"
    else
        echo "Group aliases added"
    fi
    
    set +e
}

main
