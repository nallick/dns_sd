//
//  TXTRecord.swift
//
//  Copyright © 2019, 2024 Purgatory Design. Licensed under the MIT License.
//

import Foundation

#if os(Linux)
import Cdns_sd
#else
import dnssd
#endif

public final class TXTRecord {

    // MARK: Internal Interface

    public var length: UInt16 {
        return TXTRecordGetLength(&self.reference)
    }

    public var bytes: UnsafeRawPointer {
        return TXTRecordGetBytesPtr(&self.reference)
    }

    public var count: Int {
        guard TXTRecordGetLength(&self.reference) > 0 else { return 0 }
        return Int(TXTRecordGetCount(self.length, self.bytes))
    }

    public var keys: [String] {
        return (0 ..< self.count).reduce(into: []) { result, index in
            guard let keyValue = try? self.keyValue(forIndex: UInt16(index)) else { return }
            result.append(keyValue.key)
        }
    }

    public var dictionary: [String: Data] {
        return (0 ..< self.count).reduce(into: [:]) { result, index in
            guard let keyValue = try? self.keyValue(forIndex: UInt16(index)) else { return }
            result[keyValue.key] = keyValue.value
        }
    }

    public var strings: [String: String] {
        return self.dictionary.compactMapValues {
            String(data: $0, encoding: .utf8)
        }
    }

    public init() {
        var reference = TXTRecordRef()
        TXTRecordCreate(&reference, 0, nil)
        self.reference = reference
    }

    public convenience init(_ dictionary: [String: Data]) throws {
        self.init()

        for (key, value) in dictionary {
            let error = self.setValue(forKey: key, value: value)
            guard error == .noError else { throw error }
        }
    }

    public convenience init(_ strings: [String: String]) throws {
        self.init()

        for (key, value) in strings {
            let error = self.setValue(forKey: key, value: value)
            guard error == .noError else { throw error }
        }
    }

    deinit {
        TXTRecordDeallocate(&self.reference)
    }

    public subscript(key: String) -> Data? {
        return self.value(forKey: key)
    }

    public func contains(key: String) -> Bool {
        return TXTRecordContainsKey(self.length, self.bytes, key) != 0
    }

    public func value(forKey key: String) -> Data? {
        var valueLength: UInt8 = 0
        let valuePointer = TXTRecordGetValuePtr(self.length, self.bytes, key, &valueLength)
        guard valueLength != 0, let value = valuePointer else { return nil }
        return Data(bytes: value, count: Int(valueLength))
    }

    public func string(forKey key: String) -> String? {
        guard let data: Data = self.value(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func setValue(forKey key: String, value: String?) -> DNSService.Error {
        if let value = value {
            guard let data = value.data(using: .utf8) else { return .badParam }
            return self.setValue(forKey: key, value: data)
        } else {
            let error = TXTRecordSetValue(&self.reference, key, 0, nil)
            return DNSService.Error.from(error)
        }
    }

    public func setValue(forKey key: String, value: Data) -> DNSService.Error {
        return value.withUnsafeBytes { dataPointer in
            let error = TXTRecordSetValue(&self.reference, key, UInt8(value.count), dataPointer.baseAddress)
            return DNSService.Error.from(error)
        }
    }

    public func removeValue(forKey key: String) -> DNSService.Error {
        let error = TXTRecordRemoveValue(&self.reference, key)
        return DNSService.Error.from(error)
    }

    public func keyValue(forIndex index: UInt16) throws -> (key: String, value: Data) {
        var valueLength: UInt8 = 0
        var valuePointer: UnsafeRawPointer?
        var keyBuffer = [Int8](repeating: 0, count: 256)
        let error = TXTRecordGetItemAtIndex(self.length, self.bytes, index, UInt16(keyBuffer.count), &keyBuffer, &valueLength, &valuePointer)
        guard error == kDNSServiceErr_NoError else { throw DNSService.Error.from(error) }
        let key = String(cString: keyBuffer)
        guard valueLength != 0, let value = valuePointer else { return (key, Data()) }
        return (key, Data(bytes: value, count: Int(valueLength)))
    }

    // MARK: Internal Interface

    internal var reference: TXTRecordRef

    internal convenience init(buffer: UnsafePointer<UInt8>?, length: UInt16) {
        self.init()
        let count = TXTRecordGetCount(length, buffer)
        guard count > 0 else { return }

        var valueLength: UInt8 = 0
        var valuePointer: UnsafeRawPointer?
        var keyBuffer = [Int8](repeating: 0, count: 256)

        for index in 0 ..< count {
            let error = TXTRecordGetItemAtIndex(length, buffer, index, UInt16(keyBuffer.count), &keyBuffer, &valueLength, &valuePointer)
            guard error == kDNSServiceErr_NoError else { continue }
            _ = TXTRecordSetValue(&self.reference, keyBuffer, valueLength, valuePointer)
        }
    }
}

extension TXTRecord: Collection {

    public typealias Index = UInt16
    public typealias Element = Data

    public var startIndex: Index {
        return 0
    }

    public var endIndex: Index {
        return Index(self.count)
    }

    public func index(after i: Index) -> Index {
        return i + 1
    }

    public subscript(position: Index) -> Element {
        let keyValue = try! self.keyValue(forIndex: position)
        return keyValue.value
    }
}

extension TXTRecord: Hashable {

    public static func == (lhs: TXTRecord, rhs: TXTRecord) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return lhs.dictionary == rhs.dictionary
    }

    public func hash(into hasher: inout Hasher) {
        for index in 0 ..< self.count {
            guard let keyValue = try? self.keyValue(forIndex: UInt16(index)) else { continue }
            hasher.combine(keyValue.key)
            hasher.combine(keyValue.value)
        }
    }
}
