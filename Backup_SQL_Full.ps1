#Variables
$Destination = ""
$BDD1 = ""
$BDD2 = ""
$sqlserver = ""
$Days = ""

#Renomme les sauvegardes précédentes avec la date du jour / Rename previous backups adding today's date
Get-ChildItem $Destination+$BDD1 | ForEach-Object {          
Rename-Item $_.FullName $BDD1+"_$(Get-Date $_.CreationTime -Format "ddMMyyyy").BAK"
}
Get-ChildItem $Destination+$BDD2 | ForEach-Object {          
Rename-Item $_.FullName $BDD2+"_$(Get-Date $_.CreationTime -Format "ddMMyyyy").BAK"
}

#Récupère la date X jours en arrière / Get date X days before
$Versions = (Get-Date).AddDays(-$Days)

#Supprime tous les fichiers .BAK qui ont été créés il y a plus de X jours / Delete all .BAK files older than X days
Get-ChildItem -path $Destination+'*' -include *.BAK | ForEach-Object {

    $DateCreation = Get-Date $_.CreationTime

    if ($DateCreation -lt $Versions)
    {
        Remove-Item -LiteralPath $_.FullName
    }
}

#Requete SQL de sauvegarde de toutes les bases qui ne sont pas des bases par défaut (il faut déclarer le chemin dans @path) / SQL request, backup every databases that are not default databases (you have to declare the @path)
$sql ="
DECLARE @name VARCHAR(50) -- database name  
DECLARE @path VARCHAR(256) -- path for backup files  
DECLARE @fileName VARCHAR(256) -- filename for backup  
DECLARE @fileDate VARCHAR(20) -- used for file name 

SET @path = ''  


DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb','ReportServer','ReportServerTempDB')  

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   

WHILE @@FETCH_STATUS = 0   
BEGIN   
       SET @fileName = @path + @name + '.BAK'  
       BACKUP DATABASE @name TO DISK = @fileName  

       FETCH NEXT FROM db_cursor INTO @name   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor 
"
#Execute la commande sql en désactivant le timeout / Run SQL without timeout
Invoke-Sqlcmd -ServerInstance $sqlserver -Database msdb -Query $sql -querytimeout 0

#Preparation mail / Email setup
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPServer = ""
$SMTPPort = ""
$Username = ""
$Password = ""
$to = ""
$body = ""
$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);

#Recupere la date du jour / Get today's date
$date = Get-Date -Format "dd/MM/yyyy"

#Recupere la description des events MSSQLSERVER du jour avec l'id 3041 ou 3014 (Resussite ou echec) / Get MSSQLSERVER event details from today with id 3041 or 3014 (succes or failure)
$message = Get-EventLog -LogName Application -Source MSSQLSERVER -After $date | Where {($_.EventID -eq 3041 -or $_.EventID -eq 3014)} | Select-Object -Property Message

#Si l'objet "message" contient le nom de la base c'est que la sauvegarde n'a pas fonctionné, déclenche alors l'envoi d'email echec / If the object "messge" contains the databases's name we can assume the backup didn't work then send a failure email
if ($message -match $BDD1)
{
    #Envoi mail echec / Failure email
    $subject = "[ECHEC] Sauvegarde XXXXX a echouee"
	$message = New-Object System.Net.Mail.MailMessage
	$message.subject = $subject
	$message.body = $body
	$message.to.add($to)
	$message.from = $username
	$smtp.send($message)
}

#Si l'objet "message" ne contient pas le nom de la base c'est que la sauvegarde a pas fonctionné, déclenche alors l'envoi d'email reussite / If the object "message" doesn't contain the databse's name we can assume the backup worked then send a succes email
else
{
    #Envoi mail succes / Success email
    $subject = "Sauvegarde SQL XXXXX realisee avec succes"
	$message = New-Object System.Net.Mail.MailMessage
	$message.subject = $subject
	$message.body = $body
	$message.to.add($to)
	$message.from = $username
	$smtp.send($message)
}

#Répeter pour chaque base de données / Repeat for each database
$date = Get-Date -Format "dd/MM/yyyy"

$message = Get-EventLog -LogName Application -Source MSSQLSERVER -After $date | Where {($_.EventID -eq 3041 -or $_.EventID -eq 3014)} | Select-Object -Property Message

if ($message -match $BDD2)
{

    $subject = "[ECHEC] Sauvegarde XXXXX a echouee"
	$message = New-Object System.Net.Mail.MailMessage
	$message.subject = $subject
	$message.body = $body
	$message.to.add($to)
	$message.from = $username
	$smtp.send($message)
}

else
{

    $subject = "Sauvegarde XXXXX realisee avec succes"
	$message = New-Object System.Net.Mail.MailMessage
	$message.subject = $subject
	$message.body = $body
	$message.to.add($to)
	$message.from = $username
	$smtp.send($message)
}
