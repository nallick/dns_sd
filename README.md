# dns_sd

A Swift language friendly wrapper for the dns_sd library for network service discovery, also known as (or compatibile with) Bonjour, Zeroconf, Avahi and mDNS. This library is probably most useful on Linux, since Apple platforms include the Bonjour API in Foundation. It has been tested for typical publish, browse and resolve patterns on Raspian Buster, less so for domain enumeration and record query.

For in depth information: [DNS Service Discovery Programming Guide](https://developer.apple.com/library/archive/documentation/Networking/Conceptual/dns_discovery_api/Introduction.html#//apple_ref/doc/uid/TP40002475-SW1)

### For example, to browse for a service:
````
#if os(macOS)
    import dns_sd

    enum BrowseError: Error { case didNotSearch }
    typealias BrowseCompletion = (Result<Set<DNSService.LocatedService>, BrowseError>) -> Void

    func browseServices(ofType type: String = "_http._tcp", inDomain domain: String = "", completion: @escaping BrowseCompletion) {
        let result = DNSService.browseServices(ofType: type, inDomain: domain,
            errorCallback: { error in
                completion(Result.failure(.didNotSearch))
            },
            serviceCallback: { service, locatedService in
                if !locatedService.flags.contains(.moreComing) {
                    service.stop()
                    completion(Result.success(self.locatedServices))  // return the last service
                }
            })

        if case .failure(let error) = result {
            completion(Result.failure(.didNotSearch))
        }
    }
````

### Linux preconditions:
````
sudo apt-get install pkg-config 
sudo apt install libavahi-compat-libdnssd-dev
````

### Use:

To add dns_sd to your project, declare a dependency in your Package.swift file,
````
.package(url: "https://github.com/nallick/dns_sd.git", from: "1.0.0"),
````
and add the dependency to your target:
````
.target(name: "MyProjectTarget", dependencies: ["dns_sd"]),
````
