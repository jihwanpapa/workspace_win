expect -c '
set timeout 1
spawn sh -c "echo \"jinyoung.hur@smcs-ssh-hub-ue1a-prd-arm-01:~:> \"; sleep 1"
expect {
    -re {[]$#>%] ?} {
        puts "\nMATCHED!"
    }
    eof {
        puts "\nEOF!"
    }
    timeout {
        puts "\nTIMED OUT!"
    }
}
'
