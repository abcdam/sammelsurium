#!/bin/bash
# tool to create snapshots of all logical volumes inside a logical group

# todo -> read id and multiplicator from user input 
vol_group_id="base-vg"
DATE=$(date +%Y%m%d)
real2bup_spacereq_factor=0.2


create_snapshot() {
    local lv_name=$1

    # determine size of the volume for which a snapshot will be taken
    lv_current_size_mb=$(lvs --noheadings --units m -o lv_size --nosuffix /dev/$vol_group_id/$lv_name 2>/dev/null | awk '{print $1}')
    
    # calculate space assigned to the new snapshot
    snap_size_mb=$(echo "$lv_current_size_mb * $real2bup_spacereq_factor" | bc)
    
    lvcreate --size ${snap_size_mb}M --snapshot --name ${lv_name}_${DATE}.snap /dev/$vol_group_id/$lv_name
    if [ $? -ne 0 ]; then
	echo "creating snapshot failed. fix errors first before rerunning. Aborted"
	exit 1
    fi
    echo "/dev/$vol_group_id/$lv_name ---> /dev/$vol_group_id/${lv_name}_${DATE}.snap"
}

for LV in $(lvs --noheadings --options lv_name $vol_group_id 2>/dev/null | awk '{print $1}'); do
    create_snapshot $LV
done
echo "done."

