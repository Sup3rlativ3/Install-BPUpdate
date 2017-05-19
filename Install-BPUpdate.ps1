#Requires -RunAsAdministrator
[CmdletBinding()]
param ( [string]$Date = (get-date -Format yymmdd),
        [string]$Destination = "C:\BPUpdates",
        [String]$UpdateType = "inc",
	    [string]$DownloadURL = "http://wpc.c567.edgecastcdn.net/00C567/",
        [string]$FileName = "BPS_Data_"$UpdateType
	    [string]$OutFileName
)

#Check to see if the download folder exists and if not create it.
If(!(test-path $Destination))
    {
        New-Item $Destination
    }

#Determine if a value has been passed via a parameter and if not configure it ourselves.
If($FileName = "inc")
    {
        If($UpdateType = "inc")
            {
                $FileName = ""BPS_DATA_"$Date"_inc.exe""
            }
            ElseIf($UpdateType = "comprev1")
                {
                    $FileName = ""BPS_DATA_"$Date"_comprev1.exe""
                }
            Else
                {
                    Write-host "I don't understand this type of update. Please choose Inclusive or Comprehensive."
        }
                }
    }


#Determine the type of update to be applied
If($UpdateType = "Inclusive")
    {
        Invoke-WebRequest $DownloadURL$FileName
    }
     ElseIf($UpdateType = "Comprehensive")
        {
            
        }
    Else
        {
            Write-host "I don't understand this type of update. Please choose Inclusive or Comprehensive."
        }


#Download the file to the download folder
Invoke-WebRequest $DownloadURL -OutFile $OutFileName


#Start the update installer silently
Start-Process -FilePath $Destination\$FileName -ArgumentList ('/s')
