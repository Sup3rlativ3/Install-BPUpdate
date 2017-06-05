#Requires -RunAsAdministrator
[CmdletBinding()]
param ( [string]$Date = (get-date -Format yymmdd),
        [string]$Destination = "C:\BPUpdates",
	    [string]$DownloadURL = "http://wpc.c567.edgecastcdn.net/00c567/BPS_Data_"+$Date+"_inc.exe",
	    [string]$OutFileName = "BPS_Data_"+$Date+"_inc.exe"
)

###############
#    NOTICE   #   This MUST be run on your Best Practice server.
###############

#Check to see if the download folder exists and if not create it.
if(!(test-path $Destination))
    {
        New-Item $Destination
    }

TRY {
	#Download the file to the download folder
	Invoke-WebRequest $DownloadURL -OutFile $OutFileName

    write-host "Starting install..." -forgroundcolor Green
	#Start the update installer silently
	Start-Process -FilePath $Destination\$OutFileName -ArgumentList ('/s')
    }
CATCH {
	write-host "No download available" -foregroundcolor Red
      }

