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
