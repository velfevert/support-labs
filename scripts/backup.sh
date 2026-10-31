#!/usr/bin/env bash
if [[ $# -eq 2 ]]; then
	source_dir="$1"
	backup_dir="$2"
	today=$(date +%Y%m%d-%H%M%S)
	total_path="${backup_dir}/backup-${today}.tar.gz"
	if [[ ! -d "$source_dir" ]]; then
		printf '%s is not a directory\n' "$source_dir" >&2
		exit 3
	fi
	if ! mkdir -p "$backup_dir"; then
		printf 'Backup directory %s is not create\n' "$backup_dir" >&2
		exit 4
	fi
	if tar -czf "$total_path" -C "$source_dir" . ; then
		printf 'Backup created: %s\n' "$total_path"
		exit 0
	else
		printf 'Backup %s is not create\n' "$total_path" >&2
		exit 5
	fi
else
	printf 'Usage: %s <SOURCE> <DESTINATION>\n' "$0" >&2
	exit 2 
fi
