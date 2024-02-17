//
//  DNSRecord.swift
//
//  Copyright © 2019, 2024 Purgatory Design. Licensed under the MIT License.
//

import Foundation

#if os(Linux)
import Cdns_sd
#else
import dnssd
#endif

public final class DNSRecord {

    public typealias RegisterRecordCallback = (DNSService, DNSRecord, DNSService.Error) -> Void

    // MARK: Internal Interface

    internal let reference: DNSRecordRef

    internal init(_ reference: DNSRecordRef) {
        self.reference = reference
    }

    deinit {
        DNSServiceRefDeallocate(self.reference)
    }

    internal static func registerRecord(service: DNSService, fullName: String, flags: DNSService.Flags, interfaceIndex: UInt32, resourceRecordType: DNSService.ServiceType, resourceRecordClass: DNSService.ServiceClass = .in, record: Data, timeToLive: UInt32, callback: @escaping RegisterRecordCallback) -> Result<DNSRecord, DNSService.Error> {
        guard let serviceReference = service.reference else { return .failure(.invalid) }
        return record.withUnsafeBytes { recordPointer in
            var recordReference: DNSRecordRef?
            let identifier = DNSService.identifier()
            let error = DNSServiceRegisterRecord(serviceReference, &recordReference, 0, interfaceIndex, fullName, resourceRecordType.rawValue, resourceRecordClass.rawValue, UInt16(record.count), recordPointer.baseAddress, timeToLive, dnsServiceRegisterRecordReply, identifier)
            guard error == kDNSServiceErr_NoError else { identifier.deallocate(); return Result.failure(DNSService.Error.from(error)) }
            guard let dnsRecord = recordReference else { identifier.deallocate(); return Result.failure(.unknown) }

            let result = DNSRecord(dnsRecord)
            DNSRecord.activeRegistration[identifier] = RegistrationInfo(service: service, record: result, callback: callback)
            return Result.success(result)
        }
    }

    fileprivate static var activeRegistration: [DNSService.Identifier: RegistrationInfo] = [:]

    fileprivate struct RegistrationInfo {
        let service: DNSService
        let record: DNSRecord
        let callback: RegisterRecordCallback
    }
}

private func dnsServiceRegisterRecordReply(sdRef: DNSServiceRef?, recordRef: DNSRecordRef?, flags: DNSServiceFlags, errorCode: DNSServiceErrorType, context: UnsafeMutableRawPointer?) {
    DispatchQueue.main.async {
        guard let identifier = context else { return }
        defer { identifier.deallocate() }
        guard let registrationInfo = DNSRecord.activeRegistration[identifier] else { return }
        DNSRecord.activeRegistration.removeValue(forKey: identifier)

        let error = DNSService.Error.from(errorCode)
        registrationInfo.callback(registrationInfo.service, registrationInfo.record, error)
    }
}
