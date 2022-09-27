//
//  PeripheralListItem.swift
//  BlueToothESPTest
//
//  Created by Paul Dommer on 21.09.22.
//

import Foundation
import SwiftUI
import CoreBluetooth

struct PeripheralListItemView: View {
    
    var bluetoothManager: BluetoothManager
    var cM: CBCentralManager
    var myPeripheral: MyPeripheral
    var name: String
    var isConnected: Bool
    var textToSend: String
    
    @State private var needsUpdate: [MyPeripheral: Bool] = [:]
    
    var peripheralConnection: some View {
        // MARK: Connect Button (Handshake)
        // Connect to / Disconnect from peripheral
        Group{
            Button(action: {
                if isConnected {
                    cM.cancelPeripheralConnection(myPeripheral.peripheral)
                } else {
                    cM.connect(myPeripheral.peripheral)
                }
            }, label: {
                Text(isConnected ? "🤝" : "🫱")
            }).buttonStyle(BorderedButtonStyle())
            
            // MARK: Name of Peripheral
            Text(name)
            .onChange(of: bluetoothManager.discoveredPeripherals) { [old = bluetoothManager.discoveredPeripherals] newValue in
                // Flash the RSSI Value in Green to show that the Value has been updated
                print("OnChange")
                if(newValue?.rssi != old?.rssi){
                    self.needsUpdate[myPeripheral] = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                        self.needsUpdate[myPeripheral] = false
                    }
                }
            }
        }
        
    }
    
    var dataButtons: some View {
        // MARK: Buttons to send and recive data
        // only displayed, when connected
        Group{
            if isConnected {
                // Display something when the peripheral is connected to your device
                Button(action: {
                    bluetoothManager.sendMessageToPeripheral(peripheral: myPeripheral.peripheral, msg: textToSend)
                }, label: {
                    Text("📤")
                }).buttonStyle(BorderedButtonStyle())
                
                Button(action: {
                    if let characteristic = bluetoothManager.trChInData {
                        bluetoothManager.readFromPeripheral(peripheral: myPeripheral.peripheral, characteristic:characteristic)
                    }
                }, label: {
                    Text("📥")
                }).buttonStyle(BorderedButtonStyle())
                
            }
        }
    }
    
    var peripheralInfo: some View {
        // MARK: RSSI and Timer value
        // rssi flash in green when updated
        Group{
            Text(String(myPeripheral.rssi)).foregroundColor((needsUpdate[myPeripheral] ?? false) ? Color.green : Color.black).fontWeight(isConnected ? .bold : .regular)
            Text("(" +  String(myPeripheral.time) + ")").fontWeight(isConnected ? .bold : .regular)
        }
    }
    
    var body: some View {
        HStack{
            peripheralConnection
            dataButtons
            Spacer()
            peripheralInfo
        }
    }
}
