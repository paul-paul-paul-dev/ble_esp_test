//
//  ContentView.swift
//  BlueToothESPTest
//
//  Created by Paul Dommer on 19.09.22.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @ObservedObject private var bluetoothManager = BluetoothManager()
    
    @State private var isActive: Bool = false
    
    @State private var textToSend: String = ""
    
    var appHeader: some View {
        // MARK: Start/Stop Scanning
        HStack{
            Button {
                isActive.toggle()
                if isActive {
                    bluetoothManager.startAdvertising()
                    bluetoothManager.startScanning()
                    
                } else {
                    bluetoothManager.stopAdvertising()
                    bluetoothManager.stopScanning()
                }
            } label: {
                Text(isActive ? "🟢" : "🔴").font(.largeTitle)
            }.buttonStyle(BorderedButtonStyle())
            Spacer()
            // MARK: Currently selected Characterisic
            Text(bluetoothManager.connectingChracteristic.uuidString).foregroundColor(.gray).font(.footnote)
        }.padding(.horizontal)
    }
    
    var peripheralList: some View {
        HStack{
            if let cM = bluetoothManager.centralManager, let sortedPeripherals = bluetoothManager.discoveredPeripherals.sorted {$0.rssi > $1.rssi} {
                List(sortedPeripherals, id: \.self) { (myPeripheral: MyPeripheral) in
                    if let name = myPeripheral.name, let isConnected = bluetoothManager.connectedPeripherals.contains(myPeripheral) {
                        PeripheralListItemView(bluetoothManager: bluetoothManager, cM: cM, myPeripheral: myPeripheral, name: name, isConnected: isConnected, textToSend: textToSend)
                    }
                }
                .frame(alignment: .top)
                .padding()
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.gray, lineWidth: 2)
                )
            }
        }
    }
    
    var logView: some View {
        HStack (alignment: .top){
            // MARK: LOG View
            VStack(alignment: .leading){
                Text("Log").bold().padding(0).padding(.horizontal)
                ScrollView {
                    Text(bluetoothManager.logText)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray, lineWidth: 2))
            }
            // MARK: Send Text View
            VStack(alignment: .leading){
                HStack{
                    Text("Text to send 📤").bold()
                    Button(action: {
                        textToSend = ""
                    }) {
                        Text("❌")
                    }
                }.padding(0).padding(.horizontal)
                TextField("Type Something", text: $textToSend).frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .topLeading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16)
                        .stroke(.gray, lineWidth: 2)
                    )
            }
            
            // MARK: Multiple Buttons View
            // Clear Log/ Set Characterisitc
            VStack{
                Text("Btns").bold().padding(.horizontal)
                Button(action: {
                    bluetoothManager.logText = "Cleared Log..."
                }) {
                    Text("❌")
                }
                .buttonStyle(BorderedButtonStyle())
                Spacer()
                VStack{
                    Button(action: {
                        bluetoothManager.connectingChracteristic = TransferService.ID.dataUUID
                    }) {
                        Text("📚")
                    }
                    .buttonStyle(BorderedButtonStyle())
                    Button(action: {
                        bluetoothManager.connectingChracteristic = TransferService.ID.writeUUID
                    }) {
                        Text("🖋")
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
            }
        }
        
    }
    var body: some View {
        appHeader
        VStack(alignment: .leading, spacing: 10) {
            peripheralList
            logView
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
