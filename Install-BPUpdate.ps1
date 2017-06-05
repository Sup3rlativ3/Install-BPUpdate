#Requires -RunAsAdministrator
[CmdletBinding()]
param ( [string]$Date = (get-date -Format yyMMdd),
        [string]$Destination = "C:\BPUpdates",
	    [string]$DownloadURL = "http://wpc.c567.edgecastcdn.net/00c567/BPS_Data_"+$Date+"_inc.exe",
	    [string]$OutFileName = "BPS_Data_"+$Date+"_inc.exe",
        [string]$EventSource = "Best Practice Update Script"
)

###############
#    NOTICE   #   This MUST be run on your Best Practice server.
###############

# Check to see if the event source esists and if not create it.
# https://stackoverflow.com/questions/13851577/how-to-determine-if-an-eventlog-already-exists
$EventSourceExists = Get-EventLog -list | Where-Object {$_.logdisplayname -eq "$EventSource"} 
IF (!($EventSourceExists)) 
    {
        New-EventLog -LogName Application -Source $EventSource
    }


# Check to see if the download folder exists and if not create it.
if(!(Test-Path $Destination -PathType Container -ErrorAction SilentlyContinue))
    {
        New-Item $Destination -type Directory
    }

TRY {
	    # Download the file to the download folder. If this fails stop the script and write the error to $DownloadError
	    Invoke-WebRequest $DownloadURL -OutFile $OutFileName -ErrorAction Stop -ErrorVariable DownloadError
    }

    CATCH {
	        write-host "No download available" -ForegroundColor Red
            # Write an event to event viewer showing the download URL tried and the error produced.
            Write-EventLog -LogName Application -Source $EventSource -EntryType Warning -EventId 100 -Message "There was no download available. The download URL tried was $DownloadURL `r`n`n $DownloadError"
            Exit
          }

TRY {
        write-host "Starting install..." -ForgroundColor Green
	    # Start the update installer silently. If it fails write the error to $InstallError.
	    Start-Process -FilePath $Destination\$OutFileName -ArgumentList ('/s') -ErrorAction Stop -ErrorVariable InstallError
    }

    CATCH {
            write-host "Install failed" -ForegroundColor Red
            # Write an event to event viewer advising the install failed and insert the error message produced.
            Write-EventLog -LogName Application -Source $EventSource -EventId 101 -EntryType Error -Message "The installation of the update has failed. `r`n`n $InstallError"
            Exit
          }
          
        
