#Requires -RunAsAdministrator
[CmdletBinding()]
param ( [string]$EventSource = 'Best Practice Update Script',
  [string]$Destination = "$env:HOMEDRIVE\BPUpdates",
  [string]$CurrentMonth = (Get-Date -Format MMMM),
  [string]$OutFileName = 'BPS_Data_'+$CurrentMonth+'_inc.exe'
)


###############
#    NOTICE   #   This MUST be run on your Best Practice server.
###############



# Check to see if the event source esists and if not create it.
$EventSourceExists = Get-EventLog  -LogName Application | Where-Object -FilterScript {
  $_.source -like "$EventSource"
} 

IF ($EventSourceExists -eq $Null) 
{
  New-EventLog -LogName Application -Source $EventSource
}

# Check to see if the download folder exists and if not create it.
IF ((Test-Path -Path $Destination -PathType Container -ErrorAction SilentlyContinue) -eq $False)
{
  New-Item -Path $Destination -ItemType Directory
}


# This opens the page to allow us to interact with it via the script.
$Request  = Invoke-WebRequest -Uri 'http://www.bpsoftware.net/updates/data-update/'


# This section looks for the release month on the page. It then compares it to the current month.
# If the current month and release month are the same it checks to see if it has already applied this patch.
$ReleaseMonth = $Request.ParsedHTML.getelementsbytagname('p') |
Where-Object -FilterScript {
  $_.InnerText -Like '*data update has been released*'
} |
Select-Object -ExpandProperty InnerText


#Check to see if this month has already been installed.
$AlreadyInstalled = Get-EventLog -LogName Application | Where-Object {$_.Message -like "Successfully installed the $CurrentMonth data update."}

 IF ($AlreadyInstalled)
    {
      IF ($ReleaseMonth -like $CurrentMonth)
          {
            Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 100 -Message "$CurrentMonth update has already been installed."
            Exit
          }
        
    }


# This sections finds the download links present on the data update page and then adds them to the $EXELinks variable.
$ExeLinks = $Request.ParsedHtml.getElementsByTagName('input') |
Where-Object -FilterScript {
  $_.Type -eq 'hidden' -and $_.Value -like 'http*exe' 
} |
Select-Object -ExpandProperty Value
$CurrentDownload = $ExeLinks[0]


IF ( $ReleaseMonth -Like "*$CurrentMonth*")
{
  # This section writes an event log that it is going to attempt a download.
  # It then attempts to download the file.
  # The script then checks if the download was successful and writes an event log entry.
  TRY 
  {
    Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 100 -Message "Attempting to download this months update. The URL is $CurrentDownload"
    $Download = Invoke-WebRequest -Uri $CurrentDownload -OutFile "$Destination\$OutFileName" -ErrorVariable DownloadError -PassThru

    IF ($Download.StatusCode -eq '200') 
    {
      Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 102 -Message "The download was successful. The URL is $CurrentDownload"
      Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 100 -Message "Attempting to install the $CurrentMonth update."
                            
      TRY 
      {
        # Start the update installer silently. If it fails write the error to $InstallError.
        Start-Process -FilePath $Destination\$OutFileName -ArgumentList ('/s') -ErrorAction Stop -ErrorVariable InstallError
        Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 102 -Message "Successfully installed the $CurrentMonth data update."
      }

      CATCH 
      {
        # Write an event to event viewer advising the install failed and insert the error message produced.
        Write-EventLog -LogName Application -Source $EventSource -EventId 101 -EntryType Error -Message "The installation of the update has failed. `r`n`n $InstallError"
        Exit
      }
    }
  }

  CATCH 
  {
    Write-EventLog -LogName Application -Source $EventSource -EntryType Warning -EventId 101 -Message "Failed to download the file from URL $CurrentDownload `r`n`n $DownloadError"
    Exit
  }
}
