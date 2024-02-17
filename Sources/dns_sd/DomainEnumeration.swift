//
//  DomainEnumeration.swift
//
//  Copyright © 2019, 2024 Purgatory Design. Licensed under the MIT License.
//

import Foundation

#if os(Linux)
import Cdns_sd
#else
import dnssd
#endif

extension DNSService {

    public typealias DomainEnumerationCallback = (DNSService, DomainInstance) -> Void

    public struct DomainInstance: Hashable {
        public let flags: Flags
        public let interfaceIndex: UInt32
        public let domain: String

        public init(flags: Flags, interfaceIndex: UInt32, domain: String) {
            self.flags = flags
            self.interfaceIndex = interfaceIndex
            self.domain = domain
        }
    }

    public static func enumerateDomains(flags: Flags, interfaceIndex: UInt32 = 0, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping DNSService.DomainEnumerationCallback) -> DNSServiceResult {
        var reference: DNSServiceRef?
        let identifier = DNSService.identifier()
        let error = DNSServiceEnumerateDomains(&reference, flags.rawValue, interfaceIndex, dnsServiceDomainEnumReply, identifier)
        guard error == kDNSServiceErr_NoError else { identifier.deallocate(); return Result.failure(Error.from(error)) }
        guard let dnsService = reference else { identifier.deallocate(); return Result.failure(.unknown) }
        let result = DNSDomainEnumerationService(dnsService, identifier: identifier, errorCallback: errorCallback, serviceCallback: serviceCallback)
        return Result.success(result)
    }
}

private func dnsServiceDomainEnumReply(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, replyDomain: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) {
    var result: DNSService.DomainInstance?
    let error = DNSService.Error.from(errorCode)
    if error == .noError {
        let flags = DNSService.Flags(rawValue: flags)
        let domain = replyDomain.map({ String(cString: $0) }) ?? ""
        result = DNSService.DomainInstance(flags: flags, interfaceIndex: interfaceIndex, domain: domain)
    }

    DispatchQueue.main.async {
        guard let identifier = context, let service = DNSService.activeService(with: identifier) as? DNSDomainEnumerationService else { return }
        guard let result = result else { service.stopWithError(error); return }
        service.serviceCallback(service, result)
    }
}

fileprivate final class DNSDomainEnumerationService: DNSService {

    fileprivate let serviceCallback: DomainEnumerationCallback

    fileprivate init(_ reference: DNSServiceRef, identifier: Identifier, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping DomainEnumerationCallback) {
        self.serviceCallback = serviceCallback
        super.init(reference, identifier: identifier, errorCallback: errorCallback)

        self.process()
    }
}
