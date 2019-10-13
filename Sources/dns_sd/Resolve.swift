//
//  Resolve.swift
//
//  Copyright © 2019 Purgatory Design. Licensed under the MIT License.
//

import Cdns_sd
import Foundation

extension DNSService {

    public typealias ResolveCallback = (DNSService, ResolvedService) -> Void

    public struct ResolvedService: Hashable {
        public let flags: Flags
        public let interfaceIndex: UInt32
        public let fullName: String
        public let hostTarget: String
        public let port: UInt16
        public let txtRecord: TXTRecord

        public init(flags: Flags, interfaceIndex: UInt32, fullName: String, hostTarget: String, port: UInt16, txtRecord: TXTRecord) {
            self.flags = flags
            self.interfaceIndex = interfaceIndex
            self.fullName = fullName
            self.hostTarget = hostTarget
            self.port = port
            self.txtRecord = txtRecord
        }
    }

    public static func resolveService(_ locatedService: LocatedService, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping DNSService.ResolveCallback) -> DNSServiceResult {
        return self.resolveService(named: locatedService.name, ofType: locatedService.type, inDomain: locatedService.domain, interfaceIndex: locatedService.interfaceIndex, errorCallback: errorCallback, serviceCallback: serviceCallback)
    }

    public static func resolveService(named name: String, ofType type: String, inDomain domain: String, interfaceIndex: UInt32, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping DNSService.ResolveCallback) -> DNSServiceResult {
        var reference: DNSServiceRef?
        let identifier = DNSService.identifier()
        let error = DNSServiceResolve(&reference, 0, interfaceIndex, name, type, domain, dnsServiceResolveReply, identifier)
        guard error == kDNSServiceErr_NoError else { identifier.deallocate(); return Result.failure(Error.from(error)) }
        guard let dnsService = reference else { identifier.deallocate(); return Result.failure(.unknown) }
        let result = DNSResolveService(dnsService, identifier: identifier, errorCallback: errorCallback, serviceCallback: serviceCallback)
        return Result.success(result)
    }
}

private func dnsServiceResolveReply(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, fullname: UnsafePointer<Int8>?, hosttarget: UnsafePointer<Int8>?, port: UInt16, txtLen: UInt16, txtRecord: UnsafePointer<UInt8>?, context: UnsafeMutableRawPointer?) {
    var result: DNSService.ResolvedService?
    let error = DNSService.Error.from(errorCode)
    if error == .noError {
        let flags = DNSService.Flags(rawValue: flags)
        let fullName = fullname.map({ String(cString: $0) }) ?? ""
        let hostTarget = hosttarget.map({ String(cString: $0) }) ?? ""
        let hostPort = ((port & 0x00FF) << 8) | ((port & 0xFF00) >> 8)
        let txtRecord = TXTRecord(buffer: txtRecord, length: txtLen)
        result = DNSService.ResolvedService(flags: flags, interfaceIndex: interfaceIndex, fullName: fullName, hostTarget: hostTarget, port: hostPort, txtRecord: txtRecord)
    }

    DispatchQueue.main.async {
        guard let identifier = context, let service = DNSService.activeService(with: identifier) as? DNSResolveService else { return }
        guard let result = result else { service.stopWithError(error); return }
        service.serviceCallback(service, result)
    }
}

fileprivate final class DNSResolveService: DNSService {

    fileprivate let serviceCallback: ResolveCallback

    fileprivate init(_ reference: DNSServiceRef, identifier: Identifier, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping ResolveCallback) {
        self.serviceCallback = serviceCallback
        super.init(reference, identifier: identifier, errorCallback: errorCallback)

        self.process()
    }
}
