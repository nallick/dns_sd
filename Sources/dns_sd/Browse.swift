//
//  Browse.swift
//
//  Copyright © 2019 Purgatory Design. Licensed under the MIT License.
//

import Cdns_sd
import Foundation

extension DNSService {

    public typealias BrowseCallback = (DNSService, LocatedService) -> Void

    public struct LocatedService: Hashable {
        public let flags: Flags
        public let interfaceIndex: UInt32
        public let name: String
        public let type: String
        public let domain: String

        public init(flags: Flags, interfaceIndex: UInt32, name: String, type: String, domain: String) {
            self.flags = flags
            self.interfaceIndex = interfaceIndex
            self.name = name
            self.type = type
            self.domain = domain
        }
    }

    public static func browseServices(ofType type: String, inDomain domain: String? = nil, interfaceIndex: UInt32 = 0, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping DNSService.BrowseCallback) -> DNSServiceResult {
        var reference: DNSServiceRef?
        let identifier = DNSService.identifier()
        let error = DNSServiceBrowse(&reference, 0, interfaceIndex, type, domain, dnsServiceBrowseReply, identifier)
        guard error == kDNSServiceErr_NoError else { identifier.deallocate(); return Result.failure(Error.from(error)) }
        guard let dnsService = reference else { identifier.deallocate(); return Result.failure(.unknown) }
        let result = DNSBrowseService(dnsService, identifier: identifier, errorCallback: errorCallback, serviceCallback: serviceCallback)
        return Result.success(result)
    }
}

private func dnsServiceBrowseReply(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, serviceName: UnsafePointer<Int8>?, regtype: UnsafePointer<Int8>?, replyDomain: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) {
    var result: DNSService.LocatedService?
    let error = DNSService.Error.from(errorCode)
    if error == .noError {
        let flags = DNSService.Flags(rawValue: flags)
        let name = serviceName.map({ String(cString: $0) }) ?? ""
        let type = regtype.map({ String(cString: $0) }) ?? ""
        let domain = replyDomain.map({ String(cString: $0) }) ?? ""
        result = DNSService.LocatedService(flags: flags, interfaceIndex: interfaceIndex, name: name, type: type, domain: domain)
    }

    DispatchQueue.main.async {
        guard let identifier = context, let service = DNSService.activeService(with: identifier) as? DNSBrowseService else { return }
        guard let result = result else { service.stopWithError(error); return }
        service.serviceCallback(service, result)
    }
}

fileprivate final class DNSBrowseService: DNSService {

    fileprivate let serviceCallback: BrowseCallback

    fileprivate init(_ reference: DNSServiceRef, identifier: Identifier, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping BrowseCallback) {
        self.serviceCallback = serviceCallback
        super.init(reference, identifier: identifier, errorCallback: errorCallback)

        self.process()
    }
}
