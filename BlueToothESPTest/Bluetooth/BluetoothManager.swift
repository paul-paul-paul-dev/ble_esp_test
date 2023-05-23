//
//  BluetoothManager.swift
//  BlueToothESPTest
//
//  Created by Paul Dommer on 19.09.22.
//

import Foundation
import CoreBluetooth
import os
import SwiftUI

struct MyCharacterisitc: Equatable, Hashable {
    var characteristic: CBCharacteristic
    var isSubscribed: Bool
}

struct MyPeripheral: Equatable, Hashable {
    var name: String?
    var uuid: UUID
    var peripheral: CBPeripheral
    var rssi: Int
    var time: Int
    var services: [CBService]
    var characteristics: [MyCharacterisitc]
    var isConnected: Bool
}

class BluetoothManager: NSObject, ObservableObject {
    @Published var centralManager: CBCentralManager?
    @Published var peripheralManager: CBPeripheralManager?
    
    @Published var discoveredPeripherals: [MyPeripheral] = [] { didSet  {
        let diff = discoveredPeripherals.difference(from: oldValue)
        if let diffPeripheral = diff.first {
            if let oldPeripheral = oldValue.first(where: {$0.peripheral == diffPeripheral.peripheral}){
                if(diffPeripheral.rssi != oldPeripheral.rssi){
                    updatedPeripheral = diffPeripheral
                }
            }
        }
    }}
    
    @Published var updatedPeripheral: MyPeripheral? = nil
    
    @Published var isScanning: Bool = false
    @Published var isAdvertising: Bool = false;
    
    var data = Data()
    
    // Incoming // Central
    @Published var trChInData: CBCharacteristic?
    @Published var connectingChracteristic: String = TransferService.ID.dataUUID.uuidString
    
    
    // Outgoing // Peripheral
    var trChOuData: CBMutableCharacteristic?
    
    @Published var connectedCentral: CBCentral?
    
    var dataToSend = Data()
    var sendDataIndex: Int = 0
    
    static var sendingEOM = false
    
    var peripheralTimer = Timer()
    
    @Published var logText: String = "Start log..."
    
    static var TOL = 9 // seconds a device is considered "alive"
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
        self.peripheralTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.updateMyPeripherals()
        })
    }
    
    func startScanning() {
        if isScanning { return }
        if self.centralManager?.state != .poweredOn { return }
        self.centralManager?.scanForPeripherals(withServices: []) // Place Specific Services Here <- performs way better!
        isScanning = true
    }
    
    func stopScanning() {
        if !isScanning { return }
        self.centralManager?.stopScan()
        isScanning = false
    }
    
    func startAdvertising() {
        if isAdvertising { return }
        self.peripheralManager?.startAdvertising([CBAdvertisementDataLocalNameKey:"MacPaul"])
        isAdvertising = true
    }
    
    func stopAdvertising() {
        if !isAdvertising { return }
        self.peripheralManager?.stopAdvertising()
        isAdvertising = false
    }
    
    // Called every Second to reduce the timer and remove peripherals that have not been discovered for some time (9 seconds)
    func updateMyPeripherals(){
        for (index, _) in discoveredPeripherals.enumerated() {
            discoveredPeripherals[index].time -= 1
            if discoveredPeripherals[index].time <= 0 {
                // ... and remove it
                self.discoveredPeripherals.remove(at: index)
                return
                
            }
        }
    }
}
