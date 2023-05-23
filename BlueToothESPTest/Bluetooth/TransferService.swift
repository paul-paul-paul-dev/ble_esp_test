//
//  TransferService.swift
//  BlueToothESPTest
//
//  Created by Paul Dommer on 19.09.22.
//

import Foundation
import CoreBluetooth

struct TransferService {
    
    struct ID {
        // MARK: Service
        static let serviceUUID = CBUUID(string: "12345678-90ab-cdef-0123-456789abcdef")
        // MARK: Characteristics
        static let dataUUID = CBUUID(string: "11111111-90ab-cdef-0123-456789abcdef")
        static let writeUUID = CBUUID(string: "22222222-90ab-cdef-0123-456789abcdef")
    }
    
}
