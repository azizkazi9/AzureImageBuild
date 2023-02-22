### CONFIGURATION
# nodejs
$version = "4.4.7-x64"
$url = "https://nodejs.org/dist/latest-v4.x/node-v$version.msi"

# git
$git_version = "2.9.2"
$git_url = "https://github.com/git-for-windows/git/releases/download/v$git_version.windows.1/Git-$git_version-64-bit.exe"

# npm packages




#### files 

$Logfile = "$(Get-Location)\ApplicationInstall_log.txt"

$openjdk11msi = "$(Get-Location)\OpenJDK11U-jdk_x64_windows_hotspot_11.0.10_9.msi"

$OpenJDK8Umsi= "$(Get-Location)\OpenJDK8U-jdk_x64_windows_hotspot_8u282b08.msi"
$azureclimsi="$(Get-Location)\azure-cli-2.45.0.msi"
$mysqlmsi="$(Get-Location)\mysql-installer-web-community-8.0.32.0.msi"

$dotnetsdk ="$(Get-Location)\dotnet-sdk-3.1.401-win-x64.exe"
$node_msi= "$(Get-Location)\node-v14.16.1-x64.msi"
$python ="$(Get-Location)\python-3.8.0-amd64.exe"
$terraform = "$(Get-Location)\terraform_1.3.9_windows_386.zip"
$git_exe = "$(Get-Location)\Git-2.39.1-64-bit.exe"

## MSi Arguments for 


$MSIArgumentsjdk11 = "/I $openjdk11msi /quiet"
$MSIArgumentsmysql = "/I $mysqlmsi /quiet"
$MSIArgumentsjdk8 = "/I $OpenJDK8Umsi /quiet"
$MSIArgumentsazcli = "/I $azureclimsi /quiet"

$MSIArgumentsnode="/I $node_msi /quiet"
$MSIArgumentsexe = @(
    "/Silent"
   
    
)

###  Blob storage url with sas key where all application stores for oragnisation 

$AppstoreUrl = "https://azappstore.blob.core.windows.net/installer?sp=rl&st=2023-02-17T07:19:54Z&se=2023-02-22T15:19:54Z&spr=https&sv=2021-06-08&sr=c&sig=jlbaJ6V1Adfn7zSlanZ5a9suTGHL9%2Ff9gP8Va1HU2O8%3D"

# Configuring activate / desactivate Applications  install
$Isinstall_node = $TRUE
$Isinstall_git = $TRUE
$Isinstall_ajvcli = $TRUE
$Isinstall_markdownlint = $TRUE
$Isinstall_azurecli = $TRUE
$Isinstall_terraform = $TRUE
$Isinstall_python = $TRUE
$Isinstall_dotnetsdk = $TRUE
$Isinstall_openjdk8 = $TRUE
$Isinstall_openjdk11 = $TRUE
$Isinstall_mysqlserver = $TRUE


############################################################################################################


Function Logger
{
   Param ([string]$logs)

   Add-content $Logfile -value $logs
}

Logger -logs "`n----------------------------"
Logger -logs " system requirements checking  "
Logger -logs "----------------------------`n"

### require administator rights

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
   write-Warning "This setup needs admin permissions. Please run this file as admin."     
   break
}


#### download files

Logger -logs "`n----------------------------"
Logger -logs " Downloading App setup files  "
Logger -logs "----------------------------`n"
function Get-APPS {
    param (
        [Parameter(Mandatory)]
        [string]$URL,
        [string]$Path = (Get-Location)
    )
    
    $uri = $URL.split('?')[0]
    $sas = $URL.split('?')[1]

    $newurl = $uri + "?restype=container&comp=list&" + $sas 
    
    #Invoke REST API
    $body = Invoke-RestMethod -uri $newurl

    #cleanup answer and convert body to XML
    $xml = [xml]$body.Substring($body.IndexOf('<'))

    #use only the relative Path from the returned objects
    $files = $xml.ChildNodes.Blobs.Blob.Name

    #create folder structure and download files
    $files | ForEach-Object { $_; New-Item (Join-Path $Path (Split-Path $_)) -ItemType Directory -ea SilentlyContinue | Out-Null
        (New-Object System.Net.WebClient).DownloadFile($uri + "/" + $_ + "?" + $sas, (Join-Path $Path $_))
     }
}

### Loging the details activity  


Get-APPS -URL $AppstoreUrl


### nodejs version check

if (Get-Command node -errorAction SilentlyContinue) {
    $current_version = (node -v)
}
 
if ($current_version) {
    Logger -logs "[NODE] nodejs $current_version already installed"
   

}

Logger -logs "`n"

### git install

if ($Isinstall_git) {
    if (Get-Command git -errorAction SilentlyContinue) {
        $git_current_version = (git --version)
    }

    if ($git_current_version) {
        Logger -logs "[GIT] $git_current_version detected. Proceeding ..."
    } else {
       

        Logger -logs "No git version dectected"

        $download_git = $TRUE
        
        if (Test-Path $git_exe) {
            
                $download_git = $FALSE
            
        }

        if ($download_git) {
            Logger -logs "downloading the git for windows installer"
        
            $start_time = Get-Date
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($git_url, $git_exe)
            write-Output "git installer downloaded"
            write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
        }
        
        
        Logger -logs "proceeding with git install ..."
        Logger -logs "running $git_exe"
        Try{
            start-Process $git_exe -ArgumentList $MSIArgumentsexe -Wait -PassThru 

            Logger -logs " Installation Done!"
        }catch{
           Logger -logs "Error Occured"
           Logger -logs $_
          
        }
        
        
    }
}


if ($Isinstall_node) {
    
    ### download nodejs msi file
    # warning : if a node.msi file is already present in the current folder, this script will simply use it
        
    Logger -logs "`n----------------------------"
    Logger -logs "  nodejs msi file retrieving  "
    Logger -logs "----------------------------`n"

    
    

    $filename = "node.msi"
   # $node_msi = "$(Get-Location)\$filename"
    
    $download_node = $TRUE

    if (Test-Path $node_msi) {
            $download_node = $FALSE
        
    }

    if ($download_node) {
        Logger -logs "[NODE] downloading nodejs install"
        Logger -logs "url : $url"
        $start_time = Get-Date
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $node_msi)
        write-Output "$filename downloaded"
        write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    } else {
        Logger -logs "using the existing node.msi file"
    }

    ### nodejs install

    Logger -logs "`n----------------------------"
    Logger -logs " nodejs installation  "
    Logger -logs "----------------------------`n"

    Logger -logs "[NODE] running $node_msi"

    Try{
        #Start-Process $node_msi -Wait
    Start-Process "msiexec.exe" -ArgumentList $MSIArgumentsnode -Wait -NoNewWindow 
    
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 


        Logger -logs " Installation Done!"
    }catch{
       Logger -logs "Error Occured"
       Logger -logs $_
      
    }
    
    

    




    
} else {
    Logger -logs "Proceeding with the previously installed nodejs version ..."
}

### Installing Azure Cli
if($Isinstall_azurecli){

    Logger -logs "`n----------------------------"
    Logger -logs " azure cli installation  "
    

    Try{
        
        Start-Process "msiexec.exe" -ArgumentList $MSIArgumentsazcli -Wait -NoNewWindow 
        Logger -logs " Installation Done!"
        Logger -logs "----------------------------`n"
    }catch{
       Logger -logs "Error Occured"
       Logger -logs $_
       Logger -logs "----------------------------`n"
      
    }
    

}


### Installing .netsdk
if($Isinstall_dotnetsdk){

    Logger -logs "`n----------------------------"
    Logger -logs " .netsdk installation  "
    
    Try{
        
        start-Process $dotnetsdk -ArgumentList $MSIArgumentsexe -Wait -PassThru 
        Logger -logs " Installation Done!"
        Logger -logs "----------------------------`n"
    }catch{
       Logger -logs "Error Occured"
       Logger -logs $_
       Logger -logs "----------------------------`n"
      
    }
    
}


### Installing Python
if($Isinstall_python){

    
    Logger -logs "`n----------------------------"
    Logger -logs " Python installation  "
    
    Try{
        
        start-Process $python -ArgumentList $MSIArgumentsexe -Wait -PassThru 
        Logger -logs " Installation Done!"
        Logger -logs "----------------------------`n"
    }catch{
       Logger -logs "Error Occured"
       Logger -logs $_
       Logger -logs "----------------------------`n"
      
    }
    

}


##installing Terraform
if($Isinstall_terraform){

    
    Logger -logs "`n----------------------------"
    Logger -logs " Terraform Extraction  "
   

    Try{
        
        Expand-Archive -Path $terraform -DestinationPath $(Get-Location) -Force

        

        # Set up environment variable
        $path = [System.Environment]::GetEnvironmentVariable('Path','User')
        [System.Environment]::SetEnvironmentVariable('PATH', "${path};${Get-Location}", 'User')

        Logger -logs " Installation Done!"
        Logger -logs "----------------------------`n"
    }catch{
       Logger -logs "Error Occured"
       Logger -logs $_
       Logger -logs "----------------------------`n"
      
    }
    
    
}

## installing openjdk8
if($Isinstall_openjdk8)
{
    Logger -logs "`n----------------------------"
    Logger -logs " openjdk8 installation  "
   
    Try{
        
        Start-Process "msiexec.exe" -ArgumentList $MSIArgumentsjdk8 -Wait -NoNewWindow 


        Logger -logs " Installation Done!"
        Logger -logs "----------------------------`n"
    }catch{
       Logger -logs "Error Occured"
       Logger -logs $_
       Logger -logs "----------------------------`n"
      
    }
    

}

### instlling openjdk11
if($Isinstall_openjdk11){
    Logger -logs "`n----------------------------"
    Logger -logs " openjdk11 installation  "
    
    Try{
        
        Start-Process "msiexec.exe" -ArgumentList $MSIArgumentsjdk11 -Wait -NoNewWindow 



        Logger -logs " Installation Done!"
        Logger -logs "----------------------------`n"
    }catch{
       Logger -logs "Error Occured"
       Logger -logs $_
       Logger -logs "----------------------------`n"
      
    }
    
}

### Installing mysqlserver
if($Isinstall_mysqlserver){
    Logger -logs "`n----------------------------"
    Logger -logs " Mysqlserver installation  "
    
    Try{
        
        Start-Process "msiexec.exe" -ArgumentList $MSIArgumentsmysql -Wait -NoNewWindow 



        Logger -logs " Installation Done!"
        Logger -logs "----------------------------`n"
    }catch{
       Logger -logs "Error Occured"
       Logger -logs $_
       Logger -logs "----------------------------`n"
      
    }
    
}


### npm packages install

Logger -logs "`n----------------------------"
Logger -logs " npm packages installation  "
Logger -logs "----------------------------`n"

if (Get-Command ajv -errorAction SilentlyContinue) {
    $ajv_prev_v = (ajv -v)
}

if ($ajv_prev_v) {
    Logger -logs "[AJV] ajv is already installed :"
    Logger -logs $ajv_prev_v
    
    
    
        $Isinstall_ajvcli = $FALSE
    
}

if ($Isinstall_ajvcli) {
    Logger -logs "Installing ajv-cli"
    npm install --global ajv-cli
}




if (Get-Command mdlint -errorAction SilentlyContinue) {
    $mdlint_prev_v = (mdlint -v)
}

if ($mdlint_prev_v) {
    Logger -logs "[mdlint] markdownlint is already installed :"
    Logger -logs $mdlint_prev_v

        $Isinstall_markdownlint = $FALSE
    
}

if ($Isinstall_markdownlint) {
    Logger -logs "Installing markdownlint-cli2 globally"
    npm install --global markdownlint-cli2
}