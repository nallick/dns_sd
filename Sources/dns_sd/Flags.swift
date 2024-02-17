//
//  Flags.swift
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

    public struct Flags: OptionSet, Hashable {
        public let rawValue: DNSServiceFlags

        public init(rawValue: DNSServiceFlags) {
            self.rawValue = rawValue
        }

        public static let moreComing           = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsMoreComing))
        public static let add                  = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsAdd))
        public static let `default`            = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsDefault))
        public static let noAutoRename         = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsNoAutoRename))
        public static let shared               = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsShared))
        public static let unique               = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsUnique))
        public static let browseDomains        = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsBrowseDomains))
        public static let registrationDomains  = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsRegistrationDomains))
        public static let longLivedQuery       = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsLongLivedQuery))
        public static let allowRemoteQuery     = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsAllowRemoteQuery))
        public static let forceMulticast       = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsForceMulticast))
#if os(Linux)
        public static let returnCNAME          = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsReturnCNAME))
#else
        public static let returnCNAME          = Flags(rawValue: DNSServiceFlags(kDNSServiceFlagsReturnIntermediates))
#endif
    }

    public enum ServiceClass: UInt16 {
        case `in` = 1         // kDNSServiceClass_IN
    }

    public enum ServiceType: UInt16 {
        case a = 1            // kDNSServiceType_A - Host address
        case ns = 2           // kDNSServiceType_NS - Authoritative server
        case md = 3           // kDNSServiceType_MD - Mail destination
        case mf = 4           // kDNSServiceType_MF - Mail forwarder
        case cname = 5        // kDNSServiceType_CNAME - Canonical name
        case soa = 6          // kDNSServiceType_SOA   - Start of authority zone
        case mb = 7           // kDNSServiceType_MB - Mailbox domain name
        case mg = 8           // kDNSServiceType_MG - Mail group member
        case mr = 9           // kDNSServiceType_MR - Mail rename name
        case null = 10        // kDNSServiceType_NULL - Null resource record
        case wks = 11         // kDNSServiceType_WKS - Well known service
        case ptr = 12         // kDNSServiceType_PTR - Domain name pointer
        case hinfo = 13       // kDNSServiceType_HINFO - Host information
        case minfo = 14       // kDNSServiceType_MINFO - Mailbox information
        case mx = 15          // kDNSServiceType_MX - Mail routing information
        case txt = 16         // kDNSServiceType_TXT - One or more text strings
        case rp = 17          // kDNSServiceType_RP - Responsible person
        case afsdb = 18       // kDNSServiceType_AFSDB - AFS cell database
        case x25 = 19         // kDNSServiceType_X25 - X_25 calling address
        case isdn = 20        // kDNSServiceType_ISDN - ISDN calling address
        case rt = 21          // kDNSServiceType_RT - Router
        case nsap = 22        // kDNSServiceType_NSAP - NSAP address
        case nsapptr = 23     // kDNSServiceType_NSAP_PTR - Reverse NSAP lookup (deprecated)
        case sig = 24         // kDNSServiceType_SIG - Security signature
        case key = 25         // kDNSServiceType_KEY - Security key
        case px = 26          // kDNSServiceType_PX - X.400 mail mapping
        case gpos = 27        // kDNSServiceType_GPOS - Geographical position (withdrawn)
        case aaaa = 28        // kDNSServiceType_AAAA - IPv6 Address
        case loc = 29         // kDNSServiceType_LOC - Location Information
        case nxt = 30         // kDNSServiceType_NXT - Next domain (security)
        case eid = 31         // kDNSServiceType_EID - Endpoint identifier
        case nimloc = 32      // kDNSServiceType_NIMLOC - Nimrod Locator
        case srv = 33         // kDNSServiceType_SRV - Server Selection
        case atma = 34        // kDNSServiceType_ATMA - ATM Address
        case naptr = 35       // kDNSServiceType_NAPTR - Naming Authority PoinTeR
        case kx = 36          // kDNSServiceType_KX - Key Exchange
        case cert = 37        // kDNSServiceType_CERT - Certification record
        case a6 = 38          // kDNSServiceType_A6 - IPv6 Address (deprecated)
        case dname = 39       // kDNSServiceType_DNAME - Non-terminal DNAME (for IPv6)
        case sink = 40        // kDNSServiceType_SINK - Kitchen sink (experimentatl)
        case opt = 41         // kDNSServiceType_OPT - EDNS0 option (meta-RR)
        case tkey = 249       // kDNSServiceType_TKEY - Transaction key
        case tsig = 250       // kDNSServiceType_TSIG - Transaction signature
        case ixfr = 251       // kDNSServiceType_IXFR - Incremental zone transfer
        case axfr = 252       // kDNSServiceType_AXFR - Transfer zone of authority
        case mailb = 253      // kDNSServiceType_MAILB - Transfer mailbox records
        case maila = 254      // kDNSServiceType_MAILA - Transfer mail agent records
        case any = 255        // kDNSServiceType_ANY - Wildcard match
    }
}
