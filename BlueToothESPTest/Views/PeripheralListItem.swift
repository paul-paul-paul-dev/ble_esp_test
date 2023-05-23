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
    
    @ObservedObject var bluetoothManager: BluetoothManager
    var cM: CBCentralManager
    var myPeripheral: MyPeripheral
    var name: String
    var isConnected: Bool
    var textToSend: String
    
    @State var isFlashing: Bool = false
        
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
            Text(name).fontWeight(isConnected ? .bold : .regular)
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
                ScrollView(.horizontal){
                    HStack{
                        ForEach(myPeripheral.characteristics, id: \.self){ c in
                            Button {
                                if c.isSubscribed {
                                    bluetoothManager.unsubscribeToCharcteristic(peripheral: myPeripheral.peripheral, characteristic: c.characteristic)
                                } else {
                                    bluetoothManager.subscribeToCharcteristic(peripheral: myPeripheral.peripheral, characteristic: c.characteristic)
                                }
                                
                            } label: {
                                Text(c.characteristic.uuid.uuidString.prefix(4)).fontWeight(c.isSubscribed ? .bold : .regular)
                            }.buttonStyle(BorderedButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    var peripheralInfo: some View {
        // MARK: RSSI and Timer value
        // rssi flash in green when updated
        Group{
            Text(String(myPeripheral.rssi)).foregroundColor(isFlashing ? Color.green : Color.black).fontWeight(isConnected ? .bold : .regular)
            Text("(" +  String(myPeripheral.time) + ")").fontWeight(isConnected ? .bold : .regular)
                .onChange(of: bluetoothManager.updatedPeripheral) { newValue in
                    // Flash the RSSI Value in Green to show that the Value has been updated
                    // Does Not WORK
                    // TODO: Make it work
                    // No time anymore to fix this
                    
                    /*
                     if(myPeripheral.uuid == newValue?.uuid){
                        self.isFlashing = true
                         DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                             self.isFlashing = false
                         }
                    }
                     */
                    
                }
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
