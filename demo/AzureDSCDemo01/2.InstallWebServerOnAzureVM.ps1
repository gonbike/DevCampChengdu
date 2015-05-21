[string]$instance = '5137474964'
[string]$username = 'leixu'
[string]$password = 'P2ssw0rd'
[string]$svcName = "testvmservice$instance"
[string]$vmName = "vm$instance"

# Set the folder where your files will live
$workingdir = split-path $myinvocation.mycommand.path
#Include Helper functions
."$($workingdir)\CommonFunctions.ps1"

##################################
# Configuration DSC Scripts
##################################

InstallWinRMCertificateForVM -ServiceName $SvcName -Name $vmName
$secPassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($username, $secPassword)
$cimToAzure = New-AzureCimSession -ServiceName $SvcName -MachineName $vmName -Credential $cred

$ConfigData = @{
    AllNodes = @(
		@{ NodeName = "*"},
        @{
			NodeName = $cimToAzure.ComputerName
        }
    );
}

Configuration MyCompanyVisitors 
{
        Node $AllNodes.NodeName
	    {

		    #Install the IIS Role 
		    WindowsFeature IIS 
		    { 
		      Ensure = “Present” 
		      Name = “Web-Server” 
		    } 
	}
}


MyCompanyVisitors -ConfigurationData $ConfigData -Verbose -OutputPath "$($workingdir)\MyCompanyVisitors"
Start-DscConfiguration -CimSession $cimToAzure -Path "$($workingdir)\MyCompanyVisitors"  -Verbose -Wait