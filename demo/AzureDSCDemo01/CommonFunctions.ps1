
function New-AzureCimSession {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$ServiceName,
        [Parameter(Mandatory=$false, Position=1)][string]$MachineName,
        [Parameter(Mandatory=$false)][PSCredential]$Credential)

    $instance = Get-AzureVM -ServiceName $ServiceName -Name $MachineName

    # Get the URI
    $uri = Get-AzureWinRMUri -ServiceName $instance.ServiceName -Name $instance.Name

    # Try to get credentials
    if(!$Credential) {
        $Credential = Get-SecretCredential "rdp.$($instance.ServiceName)"
    }

    # Connect
    Write-Host "Creating CIM Session on $uri"
    $opt = New-CimSessionOption -SkipCACheck -SkipCNCheck -UseSsl
    New-CimSession -SessionOption $opt -ComputerName $uri.Host -Port $uri.Port -Credential $Credential
}

Function IsAdmin
{
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
    
    return $IsAdmin
}

Function InstallWinRMCertificateForVM()
{
    param([string] $ServiceName, [string] $Name)
	if((IsAdmin) -eq $false)
	{
		Write-Error "Must run PowerShell elevated to install WinRM certificates."
		return
	}
	
    Write-Host "Installing WinRM Certificate for remote access: $ServiceName $Name"
	$WinRMCert = (Get-AzureVM -ServiceName $ServiceName -Name $Name | select -ExpandProperty vm).DefaultWinRMCertificateThumbprint
	$AzureX509cert = Get-AzureCertificate -ServiceName $ServiceName -Thumbprint $WinRMCert -ThumbprintAlgorithm sha1

	$certTempFile = [IO.Path]::GetTempFileName()
	$AzureX509cert.Data | Out-File $certTempFile

	# Target The Cert That Needs To Be Imported
	$CertToImport = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certTempFile

	$store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", "LocalMachine"
	$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
	$store.Add($CertToImport)
	$store.Close()
	
	Remove-Item $certTempFile
}