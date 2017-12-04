#!/bin/bash
export PATH=$PATH:/usr/local/bin/:/usr/bin

## Automatic AWS EBS Volume Snapshot Creation & Clean-Up Script
#
# Written by Mickael Alliel (https://www.mickaelalliel.com)
# Script Github repo: https://github.com/MickaelAlliel
#
# PURPOSE: This Bash script can be used to take automatic snapshots of your Linux EC2 instance. Script process:
# - Determine volume id and region from arguments
# - Take a snapshot of the volume id
# - The script will then delete all associated snapshots taken by the script for this volume id that are older than 3 days
#
# DISCLAIMER: This script deletes snapshots (though only the ones that it creates). 
# Make sure that you understand how the script works. No responsibility accepted in event of accidental data loss.
#


## Variable Declarations ##

RETENTION_DAYS=3
CURRENT_DATE=$(date +%s)
PURGE_DATE=$(date +%s --date "$RETENTION_DAYS days")

REGION='eu-central-1'

while getopts "v:tr" option
do
	case $option in
	v)
		VOLUME_ID=$OPTARG
		;;
	t)
		RETENTION_DAYS=$OPTARG
		PURGE_DATE=$(date +%s --date "$RETENTION_DAYS days")
		;;
	r) 
		REGION=$OPTARG
		;;
	esac
done

add_tags() {
	echo 'Creating tags for new snapshot...'
	snapshot_tags="Key=CreatedBy,Value=ec2ma_autobackup"
	snapshot_tags="$snapshot_tags Key=CreatedAt,Value=$CURRENT_DATE"
	snapshot_tags="$snapshot_tags Key=PurgeAfter,Value=$PURGE_DATE"

	$(aws ec2 create-tags --resources $created_snapshot_id --region $REGION --tags $snapshot_tags)

	echo 'Tags created!'
	echo''
}

create_snapshot() {
	echo Creating new snapshot for volume $VOLUME_ID
	created_snapshot_id=$(aws ec2 create-snapshot --volume-id $VOLUME_ID --region $REGION --description 'MA EC2 Automatic Backup Script' --output text --query SnapshotId)
	echo 'Snapshot creation completed!'
	echo ''
}

get_snapshots_list() {
	echo Getting list of existing snapshots for volume $VOLUME_ID
	SNAPSHOTS_LIST=$(aws ec2 describe-snapshots --filters Name=volume-id,Values=$VOLUME_ID Name=tag:CreatedBy,Values=ec2ma_autobackup --output text --query 'Snapshots[*].SnapshotId')
}

purge_snapshots() {
	echo 'Preparing to delete old snapshots...'
	for snap_id in $SNAPSHOTS_LIST; do
		if [ -z $snap_id  ]; then
			echo 'No snapshots to purge'
		else
			purge_after=$(aws ec2 describe-snapshots --snapshot-id $snap_id --output text | grep ^TAGS.*PurgeAfter | cut -f 3)

			if [ $CURRENT_DATE > $purge_after ]; then
				$(aws ec2 delete-snapshot --snapshot-id $snap_id)
			else
				echo Snapshot $snap_id is not up for purge yet. Moving on!
			fi
		fi
	done
	echo 'Old snapshots successfully purged!'
}

echo 'Beginning MA EC2 Automatic Backup Script --'
echo $(date +%Y-%m-%H___%R:%S)

create_snapshot
add_tags

get_snapshots_list
purge_snapshots

echo 'Terminated MA EC2 Automatic Backup Script --'
echo ''
echo ''
echo ''