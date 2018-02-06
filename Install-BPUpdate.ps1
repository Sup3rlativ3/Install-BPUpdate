#Requires -RunAsAdministrator
[CmdletBinding()]
param ( [string]$EventSource = 'Best Practice Update Script',
  [string]$Destination = "$env:HOMEDRIVE\BPUpdates",
  [string]$CurrentMonth = (Get-Date -Format MMMM),
  [string]$CurrentYear = (Get-Date -Format yyyy),
  [string]$Type = $Null,
  [string]$OutFileName = 'BPS_Data_'+$CurrentMonth+$CurrentYear+'_'+$type+'.exe',
  [string]$MD5OutFileName = 'BPS_Data_'+$CurrentMonth+$CurrentYear+'_'+$type+'.md5'
)

###############
#    NOTICE   #   This MUST be run on your Best Practice server.
###############

# Set this as the progress bar has been known to slow downloads.
# https://github.com/PowerShell/PowerShell/issues/2138
$ProgressPreference = 'SilentlyContinue'

# Check to see if the event source exists and if not create it.
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

# Check to see if this month has already been installed.
$AlreadyInstalled = Get-EventLog -LogName Application | Where-Object {$_.Message -like "Successfully installed the $CurrentMonth data update."}

 IF ($AlreadyInstalled)
    {
        Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 100 -Message "$CurrentMonth update has already been installed."
        
    }

# This tests to see if a type of download has been determined (e.g. Comprehensive or Incremental) and downloads the appropiate file.
  IF ($Type = $Null)
    {
      $Type = "inc"
    }

# Required to solve https connection issue below.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# This opens the page to allow us to interact with it via the script.
$Request  = Invoke-WebRequest -Uri "https://bpsoftware.net/resources/bp-premier-downloads/" -UseBasicParsing

# This sections finds the download links present on the data update page and then adds them to the $EXELinks variable.
$ExeLinks = ($Request.links | Where-Object href -Like "*BPS_Data_*_inc.exe*") |
Select-Object -ExpandProperty href

$CurrentDownload = $ExeLinks[0]

# This sections finds the download links present on the data update page and then adds them to the $EXELinks variable.
$MD5Links = ($Request.links | Where-Object href -Like "*BPS_Data_*_inc.md5*") |
Select-Object -ExpandProperty href

$CurrentMD5Download = $MD5Links[0]

# Test to see if the current download has already been downloaded.
#IF ((Test-Path -Path "$Destination\$OutFileName" -PathType Leaf -ErrorAction SilentlyContinue) -eq $True)
#{
#  Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 101 -Message "The update file ($Destination\$OutFileName) already exists, exiting"
#  exit
#}

  # This section writes an event log that it is going to attempt a download.
  # It then attempts to download the file.
  # The script then checks if the download was successful and writes an event log entry.

    Write-host "Downloading $CurrentDownload to $Destination\$OutFileName"
    Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 100 -Message "Attempting to download this months update. The URL is $CurrentDownload"
    $Download = Invoke-WebRequest -Uri $CurrentDownload -OutFile "$Destination\$OutFileName" -ErrorVariable DownloadError -PassThru -UseBasicParsing
    Write-Host "Downloading $CurrentMD5Download to $Destination\$MD5OutFileName"
    $MD5Download = Invoke-WebRequest -Uri $CurrentMD5Download -OutFile "$Destination\$MD5OutFileName" -ErrorVariable DownloadError -PassThru -UseBasicParsing
    
    IF ($Download.StatusCode -eq '200') 
    {
      Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 102 -Message "The download was successful. The URL was $CurrentDownload and the path is $Destination\$OutFileName. The MD5 was downloaded from $CurrentMD5Download and saved as $Destination\$MD5OutFileName"
      Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 100 -Message "Attempting to install the $CurrentMonth update from $Destination\$OutFileName"

        $FileHash = Get-FileHash "$Destination\$OutFileName" -Algorithm MD5 | Select-Object -ExpandProperty Hash
        $BPHash = Get-Content -Path "$Destination\$MD5OutFileName" | Where-Object {$_ -notmatch ";"}
        $BPHash = $BPHash.split("'*'*")[0]

        IF (compare-object $FileHash $BPHash)
          {
            write-host "MD5 correct"
          }
        ELSE 
          {
            Write-Host "Blah"
            # Write an event to event viewer advising the install failed and insert the error message produced.
            Write-EventLog -LogName Application -Source $EventSource -EventId 101 -EntryType Error -Message "The MD5 hashes do not match. `r`n`n $InstallError"
            Exit  
          }  
        
      
      TRY 
      {
        # Start the update installer silently. If it fails write the error to $InstallError.
        Start-Process -FilePath $Destination\$OutFileName -ArgumentList ('/s') -ErrorAction Stop -ErrorVariable InstallError
        Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 102 -Message "Successfully installed the $CurrentMonth data update."
      }

      CATCH 
      {
         #Write an event to event viewer advising the install failed and insert the error message produced.
        Write-EventLog -LogName Application -Source $EventSource -EventId 101 -EntryType Error -Message "The installation of the update has failed. `r`n`n $InstallError"
        Exit
      }
    }
  #CATCH 
  #{
  #  Write-EventLog -LogName Application -Source $EventSource -EntryType Warning -EventId 101 -Message "Failed to download the file from URL $CurrentDownload `r`n`n $DownloadError"
  #  Exit
  #}
