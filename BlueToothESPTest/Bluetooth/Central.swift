//
//  Central.swift
//  BlueToothESPTest
//
//  Created by Paul Dommer on 19.09.22.
//

import Foundation
import os
import CoreBluetooth

/*
 * MARK: - These are functions for when your device is the CENTRAL -
 * General Purpose Functions
 */
extension BluetoothManager {
    func connectPeripheral(peripheral: CBPeripheral) {
        if peripheral.state == .connected { os_log("Already Connected"); return }
        centralManager?.connect(peripheral)
    }
    
    func disconnectPeripheral(peripheral: CBPeripheral) {
        // Don't do anything if we're not connected
        if peripheral.state != .connected { os_log("Already Disconnected"); return }
        
        for service in (peripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.isNotifying {
                    // It is notifying, so unsubscribe
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }
        // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: WRITE DATA FROM CENTRAL TO PERIPHERAL
    func sendMessageToPeripheral(peripheral: CBPeripheral, msg: String){
        guard let transferChar = self.trChInData else {
            os_log("Not trChInData Message")
            return
        }
        //maximumWriteValueLength is 524 byts
        let sendData = Data(msg.utf8)
        let mtu = peripheral.maximumWriteValueLength (for: .withoutResponse)
        
        // check to see if number of iterations completed and peripheral can accept more data
        if peripheral.canSendWriteWithoutResponse && sendData.count < mtu {
            let stringFromData = String(data: sendData, encoding: .utf8)
            os_log("Writing %d bytes: %s", sendData.count, String(describing: stringFromData))
            peripheral.writeValue(sendData, for: transferChar, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // MARK: READ DATA FROM PERIPHERAL
    func readFromPeripheral(peripheral: CBPeripheral, characteristic: CBCharacteristic){
        peripheral.readValue(for: characteristic)
    }
    
    func subscribeToCharcteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic){
        peripheral.setNotifyValue(true, for: characteristic)
        trChInData = characteristic;
        logText.append("\nSub2: " + characteristic.uuid.debugDescription)
        if let myPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral == peripheral}){
            if let myCharacteristicIndex = discoveredPeripherals[myPeripheralIndex].characteristics.firstIndex(where: { $0.characteristic == characteristic
            }){
                discoveredPeripherals[myPeripheralIndex].characteristics[myCharacteristicIndex].isSubscribed = true
            }
        }
    }
    
    func unsubscribeToCharcteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic){
        peripheral.setNotifyValue(false, for: characteristic)
        trChInData = nil;
        logText.append("\nUnsub: " + characteristic.uuid.debugDescription)
        if let myPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral == peripheral}){
            if let myCharacteristicIndex = discoveredPeripherals[myPeripheralIndex].characteristics.firstIndex(where: { $0.characteristic == characteristic
            }){
                discoveredPeripherals[myPeripheralIndex].characteristics[myCharacteristicIndex].isSubscribed = false
            }
        }
    }
}

/*
 * MARK: These are functions for when your device is the CENTRAL
 * CBCentralMangagerDelegate implementation for events
 */
extension BluetoothManager: CBCentralManagerDelegate {
    
    /*
     * Info Log for CBCentralManager state update
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var consoleLog = ""
        
        switch central.state {
        case .poweredOff:
            consoleLog = "BLE is powered off"
        case .poweredOn:
            consoleLog = "BLE is poweredOn"
        case .resetting:
            consoleLog = "BLE is resetting"
        case .unauthorized:
            consoleLog = "BLE is unauthorized"
        case .unknown:
            consoleLog = "BLE is unknown"
        case .unsupported:
            consoleLog = "BLE is unsupported"
        default:
            consoleLog = "default"
        }
        os_log("⚠️ | State: %s", consoleLog)
    }
    
    // MARK: ON DISCOVERING A NEW PERIPHERAL
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard RSSI.intValue >= -99
        else {
            os_log("Discovered perhiperal not in expected range, at %d", RSSI.intValue)
            return
        }
        
        /*
         // Cant rely on advertisment data, because when the phone is off the advertisementdata does not get sent
         // so you can only use it to like send an "I am online" Notification
         if let altName = advertisementData[CBAdvertisementDataLocalNameKey] as? String{
         os_log("___")
         os_log("%s", altName)
         }
         */
        if (peripheral.name != nil){
            // os_log("Discovered %s at %d", String(describing: peripheral.name), RSSI.intValue)
        }
        
        let myPeripheral = MyPeripheral(name: peripheral.name ?? nil, uuid: peripheral.identifier, peripheral: peripheral, rssi: RSSI.intValue, time: BluetoothManager.TOL, services: [], characteristics: [], isConnected: false)
        
        if let myDiscoveredPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral == peripheral})  {
            
            if discoveredPeripherals[myDiscoveredPeripheralIndex].name == nil{
                discoveredPeripherals[myDiscoveredPeripheralIndex].name = peripheral.name ?? nil
            }
            discoveredPeripherals[myDiscoveredPeripheralIndex].time = BluetoothManager.TOL
            discoveredPeripherals[myDiscoveredPeripheralIndex].rssi = RSSI.intValue
        } else {
            self.discoveredPeripherals.append(myPeripheral)
        }
    }
    
    // MARK: ON CONNECTION TO A PERIPHERAL
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        
        if let myPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral == peripheral}){
            if !self.discoveredPeripherals[myPeripheralIndex].isConnected {
                self.discoveredPeripherals[myPeripheralIndex].isConnected = true
                print("✅ | didConnect to:  " + ( peripheral.name ?? "unnamed-device") + "(" + peripheral.identifier.uuidString + ")")
            }
        }
        peripheral.delegate = self
        peripheral.discoverServices([])
    }
    
    // MARK: ON DISCONNECTING FROM A PERIPHERAL
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let myPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral == peripheral}){
            if(discoveredPeripherals[myPeripheralIndex].isConnected){
                discoveredPeripherals[myPeripheralIndex].isConnected = false
                discoveredPeripherals[myPeripheralIndex].services = []
                discoveredPeripherals[myPeripheralIndex].characteristics = []

                print("✅ | didDisconnectPeripheral from:  " + ( peripheral.name ?? "unnamed-device") + "(" + peripheral.identifier.uuidString + ")")
            }
        }
    }
    
    // MARK: ON ERROR CONNECTING TO A PERIPHERAL
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ | didFailToConnect: " + ( error?.localizedDescription ?? "Error"))
    }
}

/*
 * MARK: - PERIPHERAL functions when your device is the CENTRAL -
 * CBPeripheralDelegate implemntation for events
 */
extension BluetoothManager: CBPeripheralDelegate {
    
    // MARK: ON MODIFYING A SERVICES
    /*
     *  The peripheral letting us know when services have been invalidated.
     */
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        for _ in invalidatedServices {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([])
        }
    }
    
    // MARK: ON DISCOVERING A SERVICE
    /*
     *  The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let error = error {
            os_log("Error discovering services: %s", error.localizedDescription)
            return
        }
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        
        // Add services to our info
        if let myPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral == peripheral}){
            if(discoveredPeripherals[myPeripheralIndex].isConnected){
                discoveredPeripherals[myPeripheralIndex].services.append(contentsOf: peripheralServices)
            }
        }
        
        for service in peripheralServices {
            os_log("Discovered Service: %@", service.uuid)
            peripheral.discoverCharacteristics([], for: service) // [TransferService.ID.writeUUID, TransferService.ID.dataUUID]
        }
    }
    
    // MARK: ON DISCOVERING A CHARACTERISTIC
    /*
     *  The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any).
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            return
        }
        
        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else { return }
        
        // Add characteristics to our info
        if let myPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral == peripheral}){
            discoveredPeripherals[myPeripheralIndex].characteristics.append(contentsOf: serviceCharacteristics.map{ MyCharacterisitc(characteristic: $0, isSubscribed: false)})
        }
        for characteristic in serviceCharacteristics {
            os_log("Discovered Characterisitc: %@ (%@)", characteristic.uuid.debugDescription, characteristic.uuid.uuidString)
            logText.append("\nC: " + characteristic.uuid.debugDescription + "(" + characteristic.uuid.uuidString.prefix(4) + ")")
            
            
            // MARK: WHICH CHARACTERISTIC WOULD YOU LIKE TO SUBSCRIBE TO (AUTOMATICALLY)?
            // TODO: Change the Value in the code - maybe make an opt for that in the ui <- Somehow realised :S
            /*
            if characteristic.uuid.uuidString == connectingChracteristic  {
                peripheral.setNotifyValue(true, for: characteristic)
                trChInData = characteristic;
                logText.append("\nSub2: " + characteristic.uuid.debugDescription)
            }
             */
        }
    }
    
    // MARK: ON UPDATE VALUE FOR CHARACTERISTIC
    /*
     * This callback lets us know more data has arrived via notification on the characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            return
        }
        
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        os_log("Received %d bytes: %s", characteristicData.count, stringFromData)
        logText.append("\n" + stringFromData)
    }
    
    /*
     * The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        }
        
        if characteristic.isNotifying {
            // Notification has started
            os_log("Notification began on %@", characteristic.uuid.uuidString)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            os_log("Notification stopped on %@. Disconnecting", characteristic.uuid.uuidString)
        }
    }
    
    // MARK: ON READY TO SEND DATA
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        os_log("Peripheral is ready, send data")
        // writeData(peri: peripheral)
    }
}
