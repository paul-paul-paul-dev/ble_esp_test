//
//  Peripheral.swift
//  BlueToothESPTest
//
//  Created by Paul Dommer on 19.09.22.
//

import Foundation
import os
import CoreBluetooth

/*
 * MARK: These are functions for when your device is the PERIPHERAL
 * CBPeripheralManagerDelegate implementation
 */
extension BluetoothManager: CBPeripheralManagerDelegate {
        
    /*
     * General Purpose function to setup our services and characteristics, we later want to advertise if we are the peripheral
     */
    private func setupPeripheral() {
        
        // Build our service.
        
        // Start with the CBMutableCharacteristic.
        let transferCharacteristicData = CBMutableCharacteristic(type: TransferService.ID.dataUUID,
                                                                 properties: [.notify, .read],
                                                                 value: nil,
                                                                 permissions: [.readable, .writeable])
        
        let transferCharacteristicWrite = CBMutableCharacteristic(type: TransferService.ID.writeUUID,
                                                                  properties: [.notify, .read, .writeWithoutResponse],
                                                                  value: nil,
                                                                  permissions: [.readable, .writeable])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: TransferService.ID.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristicWrite]

        // And add it to the peripheral manager.
        peripheralManager?.add(transferService)
        
        // Save the characteristic for later.
        self.trChOuData = transferCharacteristicWrite
    }
    
    // MARK: SEND EOM TO CHARACTERISTIC
    func sendEOM(){
        
        guard let transferCharacteristic = trChOuData else {
            os_log("Not transferCharacteristic EOM")
            return
        }
        
        guard let pM = peripheralManager else {
            return
        }
        
        let eomSent = pM.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
        if eomSent {
            // It sent; we're all done
            BluetoothManager.sendingEOM = false
            os_log("Sent: EOM")
        }
        return
    }
    
    // MARK: SEND DATA FROM PERIPHERAL TO CENTRAL (UPDATE CHARACTERISTIC VALUE)
    func sendData(msg: String) {
        
        dataToSend = Data(msg.utf8)
        
        setupPeripheral()
        
        guard let transferCharacteristic = trChOuData else {
            return
        }
        
        guard let pM = peripheralManager else {
            return
        }
    
        // First up, check if we're meant to be sending an EOM
        if BluetoothManager.sendingEOM {
            // send it
            let didSend = pM.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            // Did it send?
            if didSend {
                // It did, so mark it as sent
                BluetoothManager.sendingEOM = false
                os_log("Sent: EOM")
            }
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        // Is there any left to send?
        if sendDataIndex >= dataToSend.count {
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        while didSend {
            
            // Work out how big it should be
            var amountToSend = dataToSend.count - sendDataIndex
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            // Copy out the data we want
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            // Send it
            didSend = pM.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            // If it didn't work, drop out and wait for the callback
            if !didSend {
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            os_log("Sent %d bytes: %s", chunk.count, String(describing: stringFromData))
            
            // It did send, so update our index
            sendDataIndex += amountToSend
            // Was it the last one?
            if sendDataIndex >= dataToSend.count {
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                BluetoothManager.sendingEOM = true
                
                //Send it
                let eomSent = pM.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
                
                if eomSent {
                    // It sent; we're all done
                    BluetoothManager.sendingEOM = false
                    os_log("Sent: EOM")
                }
                return
            }
        }
    }

    /*
     * Info Log for CBPeripheralManager state update
     */
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            os_log("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            os_log("You are not authorized to use Bluetooth")
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown peripheral manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }
    
    // MARK: ON CENTRAL SUBSCRIBES TO OUT CHARACTERISTIC
    /*
     *  Catch when someone subscribes to our characteristic
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        os_log("Central subscribed to characteristic")
        
        // Reset the index
        sendDataIndex = 0
        
        // save central
        connectedCentral = central // make this connected centrals (array)
        os_log("Someone connected to me")
        
    }
    
    // MARK: ON CENTRAL UNSUBSCRIBE FROM OUR CHARACTERISITC
    /*
     *  Recognize when the central unsubscribes
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        os_log("Central unsubscribed from characteristic")
        connectedCentral = nil
    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        sendData(msg: "Hello Central!")
        sendEOM()
    }
    
    // MARK: ON DID RECIEVE WRITE TO CHARACTERISTIC
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        os_log("didReceiveWrite")
        for aRequest in requests {
            let central = aRequest.central
            let characteristic = aRequest.characteristic
            guard let requestValue = aRequest.value,
                let stringFromData = String(data: requestValue, encoding: .utf8) else {
                    continue
            }
            os_log("Central: %s", central.identifier.uuidString)
            os_log("Characteristic: %s", characteristic.uuid.uuidString)
            os_log("Received write request of %d bytes: %s", requestValue.count, stringFromData)
            data = requestValue
            peripheral.respond(to: aRequest, withResult: CBATTError.success) // ??
        }
    }
    
    /*
     * didReceiveRead request ist triggered
     */
     func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
         os_log("didReceiveRead")
         peripheral.respond(to: request, withResult: CBATTError.success)
     }
}
