set prompt "jinyoung.hur@smcs-ssh-hub-ue1a-prd-arm-01:~:> "
set matched [regexp {[$#>%\]] ?} $prompt]
puts "Matched: $matched"
