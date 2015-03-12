btr-backup
==========

Small backup scripts for raw files, databases, etc. using Btrfs for snapshots.

The main motivation to write these scripts, was me searching and not finding a
simple yet reliable soluting to backup my Docker containers. I started with
writing a few lines of code to create a "Docker backup image" and shortly after
realized, that these scripts can easily be run standalone.

A Docker image using there scripts can be found
[here](https://registry.hub.docker.com/u/dinkel/backup/).

Normal usage would be to start a backup job every hour, which all create a new
Btrfs snapshot. This is however not a requirement.

The script has a cleanup functionality, that ensures that the latest 12
snapshots are kept, plus one snapshot in each of the last 12 days, plus one
each month in the last year and finally one snapshot every year.

Usage
-----

At this early stage, the scripts are a bit rough and are configured using a few
environment variables described below. They can either be configured beforehand

    $ export BACKUP_ROOT=/mnt/backup

    [...]

    $ ./backup.sh

or inline

    $ BACKUP_ROOT=/mnt/backup ./backup.sh

Most probably you'll need to be `root` to run these scripts (at a minimum to
create the Btrfs snapshots).

Environment variables
---------------------

### BACKUP_ROOT (mandatory)

This defines the *local* base directory where the backups are stored. It should
be a Btrfs filesystem (altough technically only the subdirectories need be).

Example:

    $ export BACKUP_ROOT=/mnt/backup

### BACKUP_PROJECT (mandatory)

The backup medium (in my case a USB hard drive) can and should hold different
backups from different applications. Therefore `BACKUP_PROJECT` is the name of a
backup "project" and this way acts as a namespace.

Example:

    $ export BACKUP_PROJECT=owncloud

### BACKUP_FILES_PATHS (optional)

If set as a list of colon-separated *absolute* paths, the files found inside
these paths are `rsync`ed to the backup medium.

Example:

    $ export BACKUP_FILES_PATHS=/var/www/data:/var/www/config

### BACKUP_MYSQL_HOST (optional)

If set, the script uses `mysqldump --all-databases` to create a full MySQL
database dump. Note that it does not fall back to `localhost` by default,
because this option also acts a trigger for the MySQL backup procedure.

Example:

    $ export BACKUP_MYSQL_HOST=localhost

### BACKUP_MYSQL_USER (optional, default "root")

This defines the user which reads the PostgreSQL database for dumping.

Example:

    $ export BACKUP_MYSQL_USER=admin

### BACKUP_MYSQL_PASSWORD (optional, default "")

This defines the password for the aforementioned `BACKUP_MYSQL_USER`. It
defaults to no password.

Example:

    $ export BACKUP_MYSQL_PASSWORD=mysecretpassword

### BACKUP_POSTGRESQL_HOST (optional)

If set, the script uses `pg_dumpall` to create a full PostgreSQL database dump.
Note that it does not fall back to `localhost` by default, because this option
also acts a trigger for the PostgreSQL backup procedure.

Example:

    $ export BACKUP_POSTGRESQL_HOST=localhost

### BACKUP_POSTGRESQL_USER (optional, default "postgres")

This defines the user which reads the PostgreSQL database for dumping.

Example:

    $ export BACKUP_POSTGRESQL_USER=owncloud

### BACKUP_POSTGRESQL_PASSWORD (optional, default "")

This defines the password for the aforementioned `BACKUP_POSTGRESQL_USER`. It
defaults to no password.

Example:

    $ export BACKUP_POSTGRESQL_PASSWORD=mysecretpassword

### BACKUP_OPENLDAP_HOST (optional)

If set, the script uses `ldapsearch` to create a full OpenLDAP database dump.
In order to use remote backups (like it is done with the databases), the
`ldapsearch` script is used instead of the local-only `slapcat`. There is a
nasty problem when using `ldapsearch`, that is a possible limit on number of
results returned set by the server (please make sure, this is not a problem for
you).

Example:

    $ export BACKUP_OPENLDAP_HOST=localhost

### BACKUP_OPENLDAP_DOMAIN (optional)

If set, this domain is transformed to the base DN that is to be backed up.

Example:

    $ export BACKUP_OPENLDAP_DOMAIN=ldap.example.org

This would create the base distinguished name of `dc=ldap,dc=example,dc=org`.

### BACKUP_OPENLDAP_USER (optional, default "admin")

This defines the user which reads the OpenLDAP database for data dumping.

Example:

    $ export BACKUP_OPENLDAP_USER=backup_user

Together with the `BACKUP_OPENLDAP_DOMAIN` this would create the `-D` (bind DN)
of `cn=backup_user,dc=ldap,dc=example,dc=org`.

### BACKUP_OPENLDAP_PASSWORD (optional, default "")

This defines the password for the aforementioned `BACKUP_OPENLDAP_USER`. It
defaults to no password.

Example:

    $ export BACKUP_OPENLDAP_PASSWORD=mysecretpassword

### BACKUP_OPENLDAP_CONFIG (optional)

OpenLDAP allows (and it is the default nowadays), that the configuration is
saved in the LDAP directory structure as well in order to allow interrupt-free
configuration changes. These configurations are all saven in the `cn=config`
tree and can be backed up if this option is set. Anything goes, something like
`true`, `1` or `yes` would be considered good choices.

Example:

    $ export BACKUP_OPENLDAP_CONFIG=true

### BACKUP_OPENLDAP_CONFIG_USER (optional, default "admin")

This defines the user which reads the OpenLDAP database for config dumping.

Example:

    $ export BACKUP_OPENLDAP_CONFIG_USER=config_backup_user

This would create the `-D` (bind DN) of `cn=config_backup_user,cn=config`.

### BACKUP_OPENLDAP_CONFIG_PASSWORD (optional, default "")

This defines the password for the aforementioned `BACKUP_OPENLDAP_CONFIG_USER`.
It defaults to no password.

Example:

    $ export BACKUP_OPENLDAP_CONFIG_PASSWORD=mysecretpassword

Comments / Help / Bugs
----------------------

I'm eager to hear your comments about this piece of software. If you find a bug
or thought of an enhancement, please fork or use the issue tracker.
