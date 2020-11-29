#!/bin/bash
# Checking Root Permissions
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
# Set how many days of backups you'd like to keep
OLDFILES=30
# Backup destination path.
BACKUPPATH=/var/www/backup
# Where your wordpress sites are stored.
SITESTORE=/var/www
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
# Clean backups older than retention period.
cleanbackups() {
  find "${BACKUPPATH}" -maxdepth 1 -type f -name '*.tar.gz' -mtime +"${OLDFILES}" -exec rm -rfv {} \;
  echo -e "\nBackups older than $OLDFILES days have been removed, if applicable."
}
# Complete rework of backup module and sitename logic required.
backup() {
  SITENAME=$(echo "$SITE" | cut -d / -f 4)
  if [ ! -d "${BACKUPPATH}/${SITENAME}" ]; then
    mkdir -p "${BACKUPPATH}/${SITENAME}" && echo -e "Created Backup Directory for ${SITE} in ${BACKUPPATH}/${SITENAME}\n"
  fi
  echo -e Backing up "${SITENAME}!\n"
  # Export Database
  wp db export "${BACKUPPATH}/${SITENAME}/${TIMESTAMP}-${SITENAME}.sql" --path="$SITE" --allow-root
  tar -czvf ${BACKUPPATH}/${SITENAME}/${TIMESTAMP}-${SITENAME}.tar.gz --exclude "$SITE/wp-content/updraft/*" ${SITE}
  echo -e "\nBackup of ${SITENAME} complete!\n"
}
# Update WordPress Core and Plugins
update() {
	sudo -u www-data wp core update --path="$SITE"
	sudo -u www-data wp plugin update --all --path="$SITE"
	sudo -u www-data wp theme update --all --path="$SITE"
}
# Check WP-CLI installation
if [ ! -f "/usr/local/bin/wp" ]; then
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o wp-cli.phar
	chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
	echo -e "\nInstalled WP-Cli at /usr/local/bin/wp\n"
fi
# WordPress Site Enumeration
SITELIST=$(find "$SITESTORE" -name wp-config.php | sed "s/wp-config.php//g")

# Clean out old backup files
cleanbackups

for SITE in ${SITELIST[@]}; do
	# Check if site is using wp-config outside webroot
	if [ -f "$SITE/wp-cron.php" ]; then
			backup
			update
			echo -e "\nUpdate of ${SITE} complete!\n"
		else
	# If wp-cron.php doesn't exist, append the webroot to site directory.
			COREDIR=$(find $SITE -name "wp-cron.php" | rev | cut -d / -f 2 | rev)
			SITE=${SITE}${COREDIR}
			backup
			update
			echo -e "\nUpdate of ${SITE} complete!\n"
	fi
done
