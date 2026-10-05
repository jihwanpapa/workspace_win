function FindProxyForURL(url, host) {
    // *.mcsvc.samsung.com domain uses the SOCKS5 proxy
    if (shExpMatch(host, "*.mcsvc.samsung.com")) {
        return "SOCKS5 localhost:1080; SOCKS localhost:1080";
    }

    // Samsung internal IP range (example if needed, but the user specifically mentioned domain)
    // if (isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0")) {
    //     return "SOCKS5 localhost:1080; SOCKS localhost:1080";
    // }

    // All other traffic goes DIRECT
    return "DIRECT";
}
