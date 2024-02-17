//
//  Register.swift
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

    public typealias DomainRegisterCallback = (DNSService, RegisteredService) -> Void

    public struct RegisteredService: Hashable {
        public let flags: Flags
        public let name: String
        public let type: String
        public let domain: String

        public init(flags: Flags, name: String, type: String, domain: String) {
            self.flags = flags
            self.name = name
            self.type = type
            self.domain = domain
        }
    }

    public static func registerService(named name: String? = nil, ofType type: String, inDomain domain: String? = nil, host: String? = nil, port: UInt16, txtRecord: TXTRecord? = nil, flags: Flags = [], interfaceIndex: UInt32 = 0, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping DNSService.DomainRegisterCallback) -> DNSServiceResult {
        var reference: DNSServiceRef?
        let identifier = DNSService.identifier()
        let networkPort = ((port & 0x00FF) << 8) | ((port & 0xFF00) >> 8)
        let error = DNSServiceRegister(&reference, flags.rawValue, interfaceIndex, name, type, domain, host, networkPort, txtRecord?.length ?? 0, txtRecord?.bytes ?? nil, dnsServiceRegisterReply, identifier)
        guard error == kDNSServiceErr_NoError else { identifier.deallocate(); return Result.failure(Error.from(error)) }
        guard let dnsService = reference else { identifier.deallocate(); return Result.failure(.unknown) }
        let result = DNSRegisterService(dnsService, identifier: identifier, errorCallback: errorCallback, serviceCallback: serviceCallback)
        return Result.success(result)
    }
}

private func dnsServiceRegisterReply(sdRef: DNSServiceRef?, flags: DNSServiceFlags, errorCode: DNSServiceErrorType, name: UnsafePointer<Int8>?, regtype: UnsafePointer<Int8>?, domain: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) {
    var result: DNSService.RegisteredService?
    let error = DNSService.Error.from(errorCode)
    if error == .noError {
        let flags = DNSService.Flags(rawValue: flags)
        let name = name.map({ String(cString: $0) }) ?? ""
        let type = regtype.map({ String(cString: $0) }) ?? ""
        let domain = domain.map({ String(cString: $0) }) ?? ""
        result = DNSService.RegisteredService(flags: flags, name: name, type: type, domain: domain)
    }

    DispatchQueue.main.async {
        guard let identifier = context, let service = DNSService.activeService(with: identifier) as? DNSRegisterService else { return }
        guard let result = result else { service.stopWithError(error); return }
        service.serviceCallback(service, result)
    }
}

fileprivate final class DNSRegisterService: DNSService {

    fileprivate let serviceCallback: DomainRegisterCallback

    fileprivate init(_ reference: DNSServiceRef, identifier: Identifier, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping DomainRegisterCallback) {
        self.serviceCallback = serviceCallback
        super.init(reference, identifier: identifier, errorCallback: errorCallback)

        self.process()
    }
}
