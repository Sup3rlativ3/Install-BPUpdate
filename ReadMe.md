Install-BPUpdate
=================

This script will check to see if an incremental Best Practice data update has been released today and if so download and install it.


 Parameters
 -------------- 
 **-Date**  
  	_Not Required._  
   _Pipeline not accepted._   
   _Named Position._   
   _No Wildcards._   
  	This fills the filename to download. You can use this if you are searching for a specific date.
  
 **-Destination**  
  	_Not Required._  
   _Pipeline not accepted._   
   _Named Position._   
   _No Wildcards._   
  	Sets the download directory for the data update file. By default this will be C:\BPUpdate
  
 **-DownloadURL**  
  	_Not Required._  
   _Pipeline not accepted._   
   _Named Position._   
   _No Wildcards._   
  	This is the URL to download the file from. This also includes the filename.
  
 **-OutFileName**  
  	_Not Required._  
   _Pipeline not accepted._   
   _Named Position._   
   _No Wildcards._   
  	This sets the name to download the file as.
    


-------------------

Exmaple usage
-------------- 

  `.\Install-BPUpdate.ps1`
        This will run the script with default. The download will be downloaded to with the original filename to C:\BPUpdates
    
  `.\Install-BPUpdate.ps1 -OutFileName "BPUPdate.exe"`
  	    This will run the script with defaults but set the saved filename to "BPUpdate.exe" (without the quotes).
   
 
