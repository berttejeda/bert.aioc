#!/bin/env bash

my_work_dir="${PWD}"
my_script_path=${0}
my_script_dir=${0%/*}
my_keyfile_name=".key.txt"
my_env_crypt_string=FjEOoJor4ffvK9o9uMwgEa6yfwptKG3CQLv4pIMUTZM=
# Preserve the original cli arguments
allargs=${@}

while (( "$#" )); do
	if [[ "$1" =~ ^--dry$ ]]; then exec_action=echo;shift;fi
	if [[ "$1" =~ ^--list$ ]]; then list=true;shift;fi
	shift;
done

if [[ $list == "true" ]];then
	# Inventory CLI
	DynamicInventorySpec=${my_work_dir}/ansible/files/inventory.py
	if [[ ! -f $DynamicInventorySpec ]];then
		echo "Error: Could not find Dynamic Inventory file at ${my_work_dir}/ansible/files/inventory.py"
		echo "Error: Make sure you are operating from the AIOC root directory"
		exit 1
	else
		INFRA_ENVIRONMENT="${my_script_dir}" ${exec_action} python $DynamicInventorySpec ${allargs}
	fi
else
	if [[ -f "${my_script_dir}/${my_keyfile_name}" ]];then
		${exec_action} python ${my_work_dir}/ansible/library/lookup_plugins/aes_crypto.py -d -k "${my_script_dir}/${my_keyfile_name}" -s "${my_env_crypt_string}"
	fi
fi
