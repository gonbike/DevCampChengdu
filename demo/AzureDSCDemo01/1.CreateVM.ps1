
[string]$username = 'leixu'
[string]$password = 'P2ssw0rd'
[string]$svcName = 'dscdemo-lx'
[string]$vmName = "dsc-$($username)"

$workingdir = split-path $myinvocation.mycommand.path

Import-AzurePublishSettingsFile -PublishSettingsFile "$($workingdir)\Microsoft Azure Enterprise 试用版-5-21-2015-credentials.publishsettings"
Select-AzureSubscription -SubscriptionName 'Microsoft Azure Enterprise 试用版'

$secPassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($username, $secPassword)

# Generate unique identifier to use in names$start = get-dateif (!$Instance) {    $Instance = $start.Ticks.ToString().Substring(8,10)    }# DSC ConfigurationConfiguration CreateAzureTestVMs{    Import-DscResource -Module xAzure    Node $AllNodes.NodeName     {        # Setup Azure PreRequisite Resources        xAzureSubscription MSDN        {            Ensure = 'Present'            AzureSubscriptionName = 'Microsoft Azure Enterprise 试用版'            AzurePublishSettingsFile = Join-Path $workingdir "Microsoft Azure Enterprise 试用版-5-21-2015-credentials.publishsettings"        }        xAzureAffinityGroup TestVMAffinity        {            Ensure = 'Present'            Name = $Node.AffinityGroup            Location = $Node.AffinityGroupLocation            Label = $Node.AffinityGroup            Description = $Node.AffinityGroupDescription            DependsOn = '[xAzureSubscription]MSDN'        }        xAzureStorageAccount TestVMStorage        {            Ensure = 'Present'            StorageAccountName = $Node.StorageAccountName            AffinityGroup = $Node.AffinityGroup            Container = $Node.ScriptExtensionsFiles            Folder = Join-Path $workingdir $Node.ScriptExtensionsFiles            Label = $Node.StorageAccountName            DependsOn = '[xAzureAffinityGroup]TestVMAffinity'        }        xAzureService TestVMService        {            Ensure = 'Present'            ServiceName = $Node.ServiceName            AffinityGroup = $Node.AffinityGroup            Label = $Node.ServiceName            Description = $Node.ServiceDescription            DependsOn = '[xAzureSubscription]MSDN'        }                # Create VM's         xAzureVM TestVM1        {            Ensure = 'Present'            Name = "VM$Instance"            ImageName = '55bc2b193643443bb879a78bda516fc8__Windows-Server-2012-R2-201504.01-zh.cn-127GB.vhd'            ServiceName = $Node.ServiceName            StorageAccountName = $Node.StorageAccountName            Windows = $True            Credential = $cred            InstanceSize = 'Small'            #ExtensionContainerName = 'scriptextensionfiles'            #ExtensionFileList = 'InstallJEA.ps1'            #ExtensionScriptName = 'InstallJEA.ps1'            DependsOn = '[xAzureService]TestVMService'        }    }}$ConfigData=    @{ 
    AllNodes = @(     
                    @{  
                        NodeName = 'localhost' 
                        #CertificateFile = Join-Path $workingdir 'publicKey.cer'
                        #Thumbprint = ''
                        PSDscAllowPlainTextPassword=$true
                        AffinityGroup = "TestVMWestUS$Instance"
                        AffinityGroupLocation = 'China North'
                        AffinityGroupDescription = 'Affinity Group for Test Virtual Machines'
                        StorageAccountName = "testvmstorage$Instance"
                        ScriptExtensionsFiles = 'scriptextensionfiles'
                        ServiceName = "testvmservice$Instance"
                        ServiceDescription = 'Service created for Test Virtual Machines'
                    }
                )
} # Create MOFCreateAzureTestVMs -OutputPath $workingdir -ConfigurationData $ConfigData# Apply MOFStart-DscConfiguration -ComputerName 'localhost' -wait -force -verbose -path $workingdir# Show DSC run time$finish = get-dateWrite-Host "Completed in " -NoNewlineWrite-host "$(New-TimeSpan $start $finish)" -ForegroundColor Green# Write Instance ID to pipelineWrite-Output $Instance

#Get-AzureRemoteDesktopFile -ServiceName $SvcName -Name $vmName -LocalPath "$($workingdir)\$($vmName)-connection.rdp"
