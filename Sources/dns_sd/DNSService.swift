//
//  DNSService.swift
//
//  Copyright © 2019 Purgatory Design. Licensed under the MIT License.
//

import Cdns_sd
import Foundation

public typealias DNSServiceResult = Result<DNSService, DNSService.Error>

public class DNSService {

    // MARK: Public Interface

    public var isActive: Bool {
        return self.reference != nil
    }

    public var socket: Int32 {
        guard let reference = self.reference else { return -1 }
        return DNSServiceRefSockFD(reference)
    }

    public func useNonblockingSocket() -> Int32 {
        let socket = self.socket
        var flags = fcntl(socket, F_GETFL, 0)
        if flags == -1 { flags = 0 }
        _ = fcntl(socket, F_SETFL, flags | O_NONBLOCK)
        return socket
    }

    public func processResult() -> DNSService.Error {
        let error = DNSServiceProcessResult(self.reference)
        return Error.from(error)
    }

    public func stop() {
        self.stopProcessing()

        if let reference = self.reference {
            DNSServiceRefDeallocate(reference)
            self.reference = nil
        }

        DNSService.activeServices.removeValue(forKey: self.identifier)
    }

    public func addRecord(_ resourceRecordType: ServiceType, record: Data, timeToLive: UInt32 = 0) -> Result<DNSRecord, DNSService.Error> {
        guard let serviceReference = self.reference else { return .failure(.invalid) }
        return record.withUnsafeBytes { recordPointer in
            var recordReference: DNSRecordRef?
            let error = DNSServiceAddRecord(serviceReference, &recordReference, 0, resourceRecordType.rawValue, UInt16(record.count), recordPointer.baseAddress, timeToLive)
            guard error == kDNSServiceErr_NoError else { return Result.failure(Error.from(error)) }
            guard let dnsRecord = recordReference else { return Result.failure(.unknown) }
            let result = DNSRecord(dnsRecord)
            return Result.success(result)
        }
    }

    public func updateRecord(_ dnsRecord: DNSRecord?, record: Data, timeToLive: UInt32 = 0) -> DNSService.Error {
        guard let serviceReference = self.reference else { return .invalid }
        return record.withUnsafeBytes { recordPointer in
            let error = DNSServiceUpdateRecord(serviceReference, dnsRecord?.reference, 0, UInt16(record.count), recordPointer.baseAddress, timeToLive)
            return DNSService.Error.from(error)
        }
    }

    public func removeRecord(_ dnsRecord: DNSRecord) -> DNSService.Error {
        guard let serviceReference = self.reference else { return .invalid }
        let error = DNSServiceRemoveRecord(serviceReference, dnsRecord.reference, 0)
        return DNSService.Error.from(error)
    }

    public func registerRecord(fullName: String, flags: DNSService.Flags, interfaceIndex: UInt32 = 0, resourceRecordType: ServiceType, resourceRecordClass: ServiceClass = .in, record: Data, timeToLive: UInt32 = 0, callback: @escaping DNSRecord.RegisterRecordCallback) -> Result<DNSRecord, DNSService.Error> {
        return DNSRecord.registerRecord(service: self, fullName: fullName, flags: flags, interfaceIndex: interfaceIndex, resourceRecordType: resourceRecordType, resourceRecordClass: resourceRecordClass, record: record, timeToLive: timeToLive, callback: callback)
    }

    public static func constructFullName(service: String?, type: String, domain: String) -> String? {
        var fullName = [Int8].init(repeating: 0, count: Int(kDNSServiceMaxDomainName))
        let error = DNSServiceConstructFullName(&fullName, service, type, domain)
        guard error == 0 else { return nil }
        return String(cString: fullName)
    }

    public static func createConnection() -> DNSServiceResult {
        var reference: DNSServiceRef?
        let error = DNSServiceCreateConnection(&reference)
        guard error == kDNSServiceErr_NoError else { return Result.failure(Error.from(error)) }
        guard let dnsService = reference else { return Result.failure(.unknown) }
        let result = DNSService(dnsService)
        return Result.success(result)
    }

    public static func reconfirmRecord(fullName: String, interfaceIndex: UInt32 = 0, resourceRecordType: ServiceType, resourceRecordClass: ServiceClass = .in, record: Data) -> DNSService.Error {
        return record.withUnsafeBytes { recordPointer in
            let error = DNSServiceReconfirmRecord(0, interfaceIndex, fullName, resourceRecordType.rawValue, resourceRecordClass.rawValue, UInt16(record.count), recordPointer.baseAddress)
            return DNSService.Error.from(error)
        }
    }

    public static func disableExternalWarnings() {
        self.externalWarningsDisabled   // reference to ensure this happens once and only once
    }

    // MARK: Internal Interface

    internal typealias Identifier = UnsafeMutableRawPointer
    internal let identifier: Identifier

    internal var reference: DNSServiceRef?

    internal init(_ reference: DNSServiceRef, identifier: Identifier = DNSService.identifier(), errorCallback: ErrorCallback? = nil) {
        self.reference = reference
        self.identifier = identifier
        self.errorCallback = errorCallback

        DNSService.activeServices[identifier] = self

        DNSService.disableExternalWarnings()
    }

    deinit {
        self.identifier.deallocate()
        if let reference = self.reference { DNSServiceRefDeallocate(reference) }
    }

    internal func stopWithError(_ error: DNSService.Error) {
        self.stop()
        self.errorCallback?(error)
    }

    internal func stopProcessing() {
        self.isProcessing = false
    }

    internal static func identifier() -> Identifier {
        return UnsafeMutableRawPointer.allocate(byteCount: 0, alignment: 0)
    }

    internal static func activeService(with identifier: Identifier) -> DNSService? {
        return self.activeServices[identifier]
    }

    internal func process() {
        #if os(Linux)
        // For Avahi, see: https://stackoverflow.com/questions/7391079/avahi-dns-sd-compatibility-layer-fails-to-run-browse-callback

        DNSService.processingQueue.async {
            let socket = self.useNonblockingSocket()

            var readFds = fd_set()
            FD.zero(&readFds)
            FD.set(socket, set: &readFds)

            self.isProcessing = true
            var error = DNSService.Error.noError
            while self.isProcessing {
                let selectResult = select(socket + 1, &readFds, nil, nil, nil)
                guard selectResult >= 0 else { error = .unknown; break }
                error = self.processResult()
                guard error == .noError else { break }
                usleep(10000)
            }

            if self.isProcessing && error != .noError {
                self.stopWithError(error)
            }
        }
        #endif
    }

    // MARK: Private

    private let errorCallback: ErrorCallback?
    private var isProcessing = false

    private static var activeServices: [DNSService.Identifier: DNSService] = [:]
    private static var processingQueue = {
        return DispatchQueue(label: "DNSServiceProcessing", qos: .background, attributes: .concurrent)
    }()

    /// Disable API upgrade nags from Avahi. This singleton is only executed once.
    ///
    private static let externalWarningsDisabled: Void = {
        #if os(Linux)
        setenv("AVAHI_COMPAT_NOWARN", "1", 0)
        #endif
    }()
}
