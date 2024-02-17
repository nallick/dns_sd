//
//  QueryRecord.swift
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

    public typealias QueryRecordCallback = (DNSService, QueryRecordResult) -> Void

    public struct QueryRecordResult: Hashable {
        public let flags: Flags
        public let interfaceIndex: UInt32
        public let fullName: String
        public let resourceRecordType: ServiceType?
        public let resourceRecordClass: ServiceClass?
        public let resourceRecord: Data
        public let timeToLive: UInt32

        public init(flags: Flags, interfaceIndex: UInt32, fullName: String, resourceRecordType: ServiceType?, resourceRecordClass: ServiceClass?, resourceRecord: Data, timeToLive: UInt32) {
            self.flags = flags
            self.interfaceIndex = interfaceIndex
            self.fullName = fullName
            self.resourceRecordType = resourceRecordType
            self.resourceRecordClass = resourceRecordClass
            self.resourceRecord = resourceRecord
            self.timeToLive = timeToLive
        }
    }

    public static func queryRecord(fullName: String, flags: Flags = [], interfaceIndex: UInt32 = 0, resourceRecordType: ServiceType, resourceRecordClass: ServiceClass = .in, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping DNSService.QueryRecordCallback) -> DNSServiceResult {
        var reference: DNSServiceRef?
        let identifier = DNSService.identifier()
        let error = DNSServiceQueryRecord(&reference, flags.rawValue, interfaceIndex, fullName, resourceRecordType.rawValue, resourceRecordClass.rawValue, dnsServiceQueryRecordReply, identifier)
        guard error == kDNSServiceErr_NoError else { identifier.deallocate(); return Result.failure(Error.from(error)) }
        guard let dnsService = reference else { identifier.deallocate(); return Result.failure(.unknown) }
        let result = DNSQueryRecordService(dnsService, identifier: identifier, errorCallback: errorCallback, serviceCallback: serviceCallback)
        return Result.success(result)
    }
}

private func dnsServiceQueryRecordReply(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, fullname: UnsafePointer<Int8>?, rrtype: UInt16, rrclass: UInt16, rdlen: UInt16, rdata: UnsafeRawPointer?, ttl: UInt32, context: UnsafeMutableRawPointer?) {
    var result: DNSService.QueryRecordResult?
    let error = DNSService.Error.from(errorCode)
    if error == .noError {
        let flags = DNSService.Flags(rawValue: flags)
        let fullName = fullname.map({ String(cString: $0) }) ?? ""
        let resourceRecordType = DNSService.ServiceType(rawValue: rrtype)
        let resourceRecordClass = DNSService.ServiceClass(rawValue: rrclass)
        let resourceRecord = rdata.map({ Data(bytes: $0, count: Int(rdlen)) }) ?? Data()
        result = DNSService.QueryRecordResult(flags: flags, interfaceIndex: interfaceIndex, fullName: fullName, resourceRecordType: resourceRecordType, resourceRecordClass: resourceRecordClass, resourceRecord: resourceRecord, timeToLive: ttl)
    }

    DispatchQueue.main.async {
        guard let identifier = context, let service = DNSService.activeService(with: identifier) as? DNSQueryRecordService else { return }
        guard let result = result else { service.stopWithError(error); return }
        service.serviceCallback(service, result)
    }
}

fileprivate final class DNSQueryRecordService: DNSService {

    fileprivate let serviceCallback: QueryRecordCallback

    fileprivate init(_ reference: DNSServiceRef, identifier: Identifier, errorCallback: @escaping ErrorCallback, serviceCallback: @escaping QueryRecordCallback) {
        self.serviceCallback = serviceCallback
        super.init(reference, identifier: identifier, errorCallback: errorCallback)

        self.process()
    }
}
