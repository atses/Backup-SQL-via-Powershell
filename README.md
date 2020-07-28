# Backup-SQL-with-Powershell
Simple full backup for MSSQL databases with Powershell, versionning and notification by email.
This script is meant to be used on small enterprise Windows servers.

#What it does
This script is meant to perform simple full backups of MSSQL databases.
- Rename previous backups adding the creation date of the backup (backup files name will match the name of the database and the date it has been backed up)
- Delete all backups older than X days (you have to set a number of your choice in the code)
- Run database's backup with a SQL command ignoring default databases
- Check Windows event viewer if the backup worked correcly or not and send an email according to the result
Backups are stored as a .BAK file in the directory of your choice. They are not compressed nor modified, just full backup.

#How to use
Variables on the beginning of the script are used to choose :
- Backup path (Windows path)
- Declare databases name you want to backup (also used for the email), you have to add as much BDDX variable as there is databases to backup
- Declare the SQL server name
- The number of versions (in days) you want to keep your backups)

Remember to declare the path for your backups in the SQL command in addition to the variable in the powershell script.
The mail setup requires simple SMTP settings to send email with the adress of your choice.
The script must be runned by the Windows task schedule with administrator privilege.
