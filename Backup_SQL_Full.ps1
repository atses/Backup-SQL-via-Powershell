#Variables
$Destination = ""
$BDD1 = ""
$BDD2 = ""
$sqlserver = ""
#Renomme les sauvegardes précédentes avec la date du jour
Get-ChildItem $Destination+$BDD1 | ForEach-Object {          
Rename-Item $_.FullName $BDD1+"_$(Get-Date $_.CreationTime -Format "ddMMyyyy").BAK"
}
Get-ChildItem $Destination+$BDD2 | ForEach-Object {          
Rename-Item $_.FullName $BDD2+"_$(Get-Date $_.CreationTime -Format "ddMMyyyy").BAK"
}

#Récupère la date 7 jours en arrière
$Date7Jours = (Get-Date).AddDays(-7)

#Supprime tous les fichiers .BAK qui ont été créés il y a plus de 7 jours
Get-ChildItem -path $Destination+'*' -include *.BAK | ForEach-Object {

    $DateCreation = Get-Date $_.CreationTime

    if ($DateCreation -lt $Date7Jours)
    {
        Remove-Item -LiteralPath $_.FullName
    }
}

#Requete SQL de sauvegarde de toutes les bases qui ne sont pas des bases par défaut (il faut déclarer le chemin dans @path)
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
#Execute la commande sql en désactivant le timeout
Invoke-Sqlcmd -ServerInstance $sqlserver -Database msdb -Query $sql -querytimeout 0

#preparation mail
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

#Check_Save_Oveo
#Recupere la date du jour
$date = Get-Date -Format "dd/MM/yyyy"

#Recupere la description des events MSSQLSERVER du jour avec l'id 3041 ou 3014 (Resussite ou echec)
$message = Get-EventLog -LogName Application -Source MSSQLSERVER -After $date | Where {($_.EventID -eq 3041 -or $_.EventID -eq 3014)} | Select-Object -Property Message

#Si l'objet "message" contient le nom de la base c'est que la sauvegarde n'a pas fonctionné, déclenche alors l'envoi d'email echec
if ($message -match $BDD1)
{
    #envoi mail echec
    $subject = "[ECHEC] Sauvegarde XXXXX a echouee"
	$message = New-Object System.Net.Mail.MailMessage
	$message.subject = $subject
	$message.body = $body
	$message.to.add($to)
	$message.from = $username
	$smtp.send($message)
}

#Si l'objet "message" ne contient pas le nom de la base c'est que la sauvegarde a pas fonctionné, déclenche alors l'envoi d'email reussite
else
{
    #envoi mail succes
    $subject = "Sauvegarde SQL XXXXX realisee avec succes"
	$message = New-Object System.Net.Mail.MailMessage
	$message.subject = $subject
	$message.body = $body
	$message.to.add($to)
	$message.from = $username
	$smtp.send($message)
}

#Recupere la date du jour
$date = Get-Date -Format "dd/MM/yyyy"
#Recupere la description des events MSSQLSERVER du jour avec l'id 3041 ou 3014 (Resussite ou echec)
$message = Get-EventLog -LogName Application -Source MSSQLSERVER -After $date | Where {($_.EventID -eq 3041 -or $_.EventID -eq 3014)} | Select-Object -Property Message
#Si l'objet "message" contient le nom de la base c'est que la sauvegarde n'a pas fonctionné, déclenche alors l'envoi d'email echec
if ($message -match $BDD2)
{
    #envoi mail echec
    $subject = "[ECHEC] Sauvegarde XXXXX a echouee"
	$message = New-Object System.Net.Mail.MailMessage
	$message.subject = $subject
	$message.body = $body
	$message.to.add($to)
	$message.from = $username
	$smtp.send($message)
}

#Si l'objet "message" ne contient pas le nom de la base c'est que la sauvegarde a pas fonctionné, déclenche alors l'envoi d'email reussite
else
{
    #envoi mail succes
    $subject = "Sauvegarde XXXXX realisee avec succes"
	$message = New-Object System.Net.Mail.MailMessage
	$message.subject = $subject
	$message.body = $body
	$message.to.add($to)
	$message.from = $username
	$smtp.send($message)
}