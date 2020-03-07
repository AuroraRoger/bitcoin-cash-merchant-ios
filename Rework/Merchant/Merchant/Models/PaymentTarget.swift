//
//  PaymentTarget.swift
//  Merchant
//
//  Created by Djuro Alfirevic on 2/25/20.
//  Copyright © 2020 Bitcoin.com. All rights reserved.
//

import Foundation
import BitcoinKit

enum PaymentTargetType: Int, Codable {
    case invalid
    case xPub
    case address
    case apiKey
}

final class PaymentTarget: Codable {
    
    // MARK: - Properties
    let address: String
    var type: PaymentTargetType

    // MARK: - Initializer
    init(address: String, type: PaymentTargetType) {
        self.address = address
        self.type = type
        
        setup()
    }
    
    // MARK: - Private API
    private func setup() {
        type = .invalid
        
        if isApiKey() {
            type = .apiKey
            return
        }
        
        if isLegacyAddress() {
            type = .address
            return
        }
        
        if isXPub() {
            type = .xPub
        }
    }
    
    private func isApiKey() -> Bool {
        return NSPredicate(format:"SELF MATCHES %@", "[a-z]{40}").evaluate(with: address)
    }
    
    private func isXPub() -> Bool {
        guard let data = Base58.decode(address) else { return false }
        
        let xpubBytes = [UInt8](data)
        
        if (xpubBytes.count != 78) { return false }
        
        let fourBytes = [UInt8](xpubBytes[0...3])
        
        let bigEndianValue = fourBytes.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
        }.pointee
        let version = UInt32(bigEndian: bigEndianValue)
        
        if (version != Constants.MAGIC_XPUB && version != Constants.MAGIC_TPUB && version != Constants.MAGIC_YPUB && version != Constants.MAGIC_UPUB && version != Constants.MAGIC_ZPUB && version != Constants.MAGIC_VPUB) {
            return false
        }
        
        let subdata = data.advanced(by: 41)
        let array = [UInt8](subdata.dropLast(subdata.count - 1))
        
        let firstByte = array[0]
        if (firstByte == 0x02 || firstByte == 0x03) {
            return true
        }
        
        return false
    }
    
    private func isLegacyAddress() -> Bool {
        if let _ = try? BitcoinAddress(cashaddr: address) {
            return true
        } else if let _ = try? BitcoinAddress(legacy: address) {
            return true
        } else if let _ = try? AddressFactory.create(address) {
            return true
        }
        
        return true
    }
    
}

private struct Constants {
    static let MAGIC_XPUB = 0x0488B21E
    static let MAGIC_TPUB = 0x043587CF
    static let MAGIC_YPUB = 0x049D7CB2
    static let MAGIC_UPUB = 0x044A5262
    static let MAGIC_ZPUB = 0x04B24746
    static let MAGIC_VPUB = 0x045F1CF6
}
