# List of disk to check, '$null' to check all disks
    $drivelist = $null;
 
# When will it trigger?
    $alertsize = 50GB;
    Write-Host ("Alert is set when space on disk is lower than "+ $alertsize / 1073741824 + " GB.");
 
# SMTP config
    # server user
        $emailuser = "";
    # server password
        $emailpass = "";
    # server address and port
        $smtp = "";
        $port = 586;
    # If your server use SSL, type there 1. Otherwise type 0.
        $ssl = 1;
    # Address from which the message will be sent
        $address = "";
    # Array with recipients
        $sendto = @("");
        
        
# Checking
            if ($drivelist -eq $null -Or $drivelist -lt 1) {
                $volumes = Get-WMIObject win32_volume;
                $drivelist = @();
                foreach ($vol in $volumes) {
                    if ($vol.DriveType -eq 3 -And $vol.DriveLetter -ne $null ) {
                        $drivelist += $vol.DriveLetter[0];
                    }
                }
            }
            foreach ($d in $drivelist) {
                Write-Host ("`r`n");
                $disk = Get-PSDrive $d;
                if ($disk.Free -lt $alertsize) {
                    Write-Host ("Disk " + $d + " space is low, sending alert.");

                    $message = new-object Net.Mail.MailMessage;
                    $message.From = $address;
                    foreach ($to in $sendto) {
                        $message.To.Add($to);
                    }
                    
# Mail subject
        $message.Subject =  ("Alert: low disk space on computer " + $env:computername);
# Message body
        $message.Body =     ("Hi,"+ " `r`n");
        $message.Body +=    ("on the computer " + $env:computername + ", on the partition " + $d + ": ");
        $message.Body +=    "disk space is low. `r`n`r`n";
        $message.Body +=    "--------------------------------------------------------------";
        $message.Body +=    "`r`n";
        $message.Body +=    ("Device name: " + $env:computername + " `r`n");
        $message.Body +=    "IP addresses: ";
        $ipAddresses = Get-NetIPAddress -AddressFamily IPv4;
        foreach ($ip in $ipAddresses) {
            if ($ip.IPAddress -like "127.0.0.1") {
                continue;
            }
            $message.Body += ($ip.IPAddress + " ");
        }
        $message.Body +=    "`r`n";
        $message.Body +=    "`r`n";
        $message.Body +=    ("Used disk space on disk: " + $d + ": " + ($disk.Used / 1073741824).toString("##.#") + " GB" + "`r`n");
        $message.Body +=    ("Free space on disk: " + $d + ": " + ($disk.Free / 1048576).toString("##.#") + " MB" + "`r`n");
        $message.Body +=    "--------------------------------------------------------------";
 
        $smtp = new-object Net.Mail.SmtpClient($smtp, $port);
        $smtp.EnableSSL = $ssl;
        $smtp.Credentials = New-Object System.Net.NetworkCredential($emailuser, $emailpass);
        $smtp.send($message);
        $message.Dispose();
        write-host "Alert sent!" ; 
    }
    else {
        Write-Host ("Disk " + $d + " has enough free space.s");
    }
}