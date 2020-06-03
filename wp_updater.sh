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
# Define all functions
cleanbackups() {
  # Clean out old backups.
  find "${BACKUPPATH}" -maxdepth 1 -type f -name '*.tar.gz' -mtime +"${OLDFILES}" -exec rm -rfv {} \;
  echo -e "\nBackups older than $OLDFILES days have been removed, if applicable."
}
backup() {
# Need to sanitize website names here before creating backup directory.
  if [ ! -d "${BACKUPPATH}/${SITE}" ]; then
    mkdir -p "${BACKUPPATH}/${SITE}" && echo -e "Created Backup Directory for ${SITE} in ${BACKUPPATH}/${SITE}\n"
  fi
  # Clean out old backup files
  cleanbackups
  echo -e Backing up "${SITE}!\n"
  # Export Database and backup of website before continuing.
  sudo -u www-data wp db export "${BACKUPPATH}/${SITE}.sql" --path="$SITE"
  tar -czf "${BACKUPPATH}/${SITE}/${SITE}-${TIMESTAMP}.tar.gz" --exclude='wp-content/updraft' .
  tar -czf "${BACKUPPATH}/${SITE}/${SITE}-${TIMESTAMP}.sql.tar.gz" "${BACKUPPATH}/${SITE}.sql" && rm "${BACKUPPATH}/${SITE}.sql"
  echo -e "\nBackup of ${SITE} complete!\n"
}
update() {
  # Update WordPress Core and Plugins
  echo $SITE
  sudo -u www-data wp plugin update --all --path="$SITE"
  sudo -u www-data wp core update --path="$SITE"
}
# Check WP-CLI installation
if [ ! -f "/usr/local/bin/wp" ]; then
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o wp-cli.phar
	chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
	echo -e "\nInstalled WP-Cli at /usr/local/bin/wp\n"
fi
# Primary application loop
SITELIST=$(find "$SITESTORE" -name "wp-cron.php" | sed "s/wp-cron.php//g")
for SITE in "${SITELIST[@]}"; do
	backup
	update
	echo -e "\nUpdate of ${SITE} complete!\n"
done