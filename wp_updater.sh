#!/bin/bash
# Set how many days of backups you'd like to keep
OLDFILES=30
# Backup destination path.
BACKUPPATH=~/backups
# Where your wordpress sites are stored.
SITESTORE=~/public_html
# The name of your wp-config files.
WPCONFIGFILE=wp-config.php
# Timestamp to add to filenames.
TIMESTAMP=$(date +%m-%d-%y)
echo -e "\n
██╗    ██╗ ██████╗ ██████╗ ██████╗ ██████╗ ██████╗ ███████╗███████╗███████╗
██║    ██║██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝
██║ █╗ ██║██║   ██║██████╔╝██║  ██║██████╔╝██████╔╝█████╗  ███████╗███████╗
██║███╗██║██║   ██║██╔══██╗██║  ██║██╔═══╝ ██╔══██╗██╔══╝  ╚════██║╚════██║
╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝██║     ██║  ██║███████╗███████║███████║
 ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
        ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗██████╗
        ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
        ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  ██████╔╝
        ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  ██╔══██╗
        ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗██║  ██║
         ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝\n
"
# Gets all wordpress site folders.
SITELIST=(`find ~/public_html/ -name "wp-config.php" | sed "s/wp-config.php//g"`)
cleanbackups() {
  # Clean out old backups.
  find "${BACKUPPATH}" -maxdepth 1 -type f -name '*.tar.gz' -mtime +"${OLDFILES}" -exec rm -rfv {} \;
  echo -e "\nBackups older than $OLDFILES days have been removed, if applicable."
}
backup() {
  if [ ! -d "${BACKUPPATH}/${SITE}" ]; then
    mkdir -p "${BACKUPPATH}/${SITE}" && echo -e "Created Backup Directory for ${SITE} in ${BACKUPPATH}/${SITE}\n"
  fi
  # Clean out old backup files
  cleanbackups
  echo -e Backing up "${SITE}!\n"
  # Export Database and backup of website before continuing.
  wp-cli db export "${BACKUPPATH}/${SITE}.sql" --path="$SITE"
  tar -czf "${BACKUPPATH}/${SITE}/${SITE}-${TIMESTAMP}.tar.gz" --exclude='wp-content/updraft' .
  tar -czf "${BACKUPPATH}/${SITE}/${SITE}-${TIMESTAMP}.sql.tar.gz" "${BACKUPPATH}/${SITE}.sql" && rm "${BACKUPPATH}/${SITE}.sql"
  echo -e "\nBackup of ${SITE} complete!\n"
}
update() {
  # Update WordPress Core and Plugins
  wp plugin update --all --path="$SITE"
  wp core update --path="$SITE"
}
for SITE in "${SITELIST[@]}"; do
	# Check if wp-config file is different than webdir
	if [[ "${SITE}" == *"html" ]]; then
		cd "${SITESTORE}/$SITE/html"
		update
		backup
	else
		update
		backup
	fi
    echo -e "\nUpdate of ${SITE} complete!\n"
done