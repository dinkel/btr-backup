btr-backup
==========

Small backup scripts for raw files, databases, etc. using Btrfs for snapshots.

The main motivation to write these scripts, was me searching and not finding a
simple yet reliable soluting to backup my Docker containers. I started with
writing a few lines of code to create a "Docker backup image" and shortly after
realized, that these scripts can easily be run standalone.

In a short while I'll link to the yet to be created Docker image that uses these
scripts in a dockerized manner with more documentation.

Normal usage would be to start a backup job every hour, which all create a new
Btrfs snapshot. This is however not a requirement.

The script has a cleanup functionality, that ensures that the latest 12
snapshots are kept, plus one snapshot in each of the last 12 days, plus one
eack month in the last year and finally one snapshot every year.

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

Comments / Help / Bugs
----------------------

I'm eager to hear your comments about this piece of software. If you find a bug
or thought of an enhancement, please fork or use the issue tracker.
