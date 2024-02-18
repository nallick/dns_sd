# dns_sd

A Swift language friendly wrapper for the dns_sd library for network service discovery, also known as (or compatibile with) Bonjour, Zeroconf, Avahi and mDNS. This library is probably most useful on Linux, since Apple platforms include the Bonjour API in Foundation. It has been tested for typical publish, browse and resolve patterns on Raspian Buster, less so for domain enumeration and record query.

For in depth information: [DNS Service Discovery Programming Guide](https://developer.apple.com/library/archive/documentation/Networking/Conceptual/dns_discovery_api/Introduction.html#//apple_ref/doc/uid/TP40002475-SW1)

### For example, to browse for a service:
````
import dns_sd
import Foundation

func browseServices(ofType type: String, inDomain domain: String? = nil, interfaceIndex: UInt32 = 0) async throws -> Set<DNSService.LocatedService> {
    try await withCheckedThrowingContinuation { continuation in
        var locatedServices = Set<DNSService.LocatedService>()
        let result = DNSService.browseServices(ofType: type, inDomain: domain, interfaceIndex: interfaceIndex,
                errorCallback: { error in
                    continuation.resume(throwing: error)
                },
                serviceCallback: { service, locatedService in
                    locatedServices.insert(locatedService)
                    if !locatedService.flags.contains(.moreComing) {
                        service.stop()
                        continuation.resume(returning: locatedServices)  // return after receiving the last service
                    }
                })

        if case .failure(let error) = result {
            continuation.resume(throwing: error)
        }
    }
}

print("Scanning...")

Task {
    let services = try await browseServices(ofType: "_http._tcp")
    print(services)
    exit(0)
}

RunLoop.current.run()
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
