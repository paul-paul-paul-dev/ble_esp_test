//
//  ContentView.swift
//  BlueToothESPTest
//
//  Created by Paul Dommer on 19.09.22.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @State private var needsUpdate: [MyPeripheral: Bool] = [:]
    
    @ObservedObject private var bluetoothManager = BluetoothManager()
    
    @State private var isActive: Bool = false
    @State private var isSorted: Bool = false
    @State private var textToSend: String = ""
    
    init(){
        UIScrollView.appearance().backgroundColor = UIColor.clear
    }
    
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
            TextField("Insert Chrateristic ID", text: $bluetoothManager.connectingChracteristic).foregroundColor(.gray).font(.footnote)
        }.padding(.horizontal)
    }
    
    var peripheralList: some View {
        HStack{
            if let cM = bluetoothManager.centralManager {
                List(bluetoothManager.discoveredPeripherals.sorted(by: { isSorted ? ($0.rssi > $1.rssi) : ($0.name ?? "Z" > $1.name ?? "A")}) , id: \.self) { (myPeripheral: MyPeripheral) in
                    if let name = myPeripheral.name {
                        PeripheralListItemView(bluetoothManager: bluetoothManager, cM: cM, myPeripheral: myPeripheral, name: name, isConnected: myPeripheral.isConnected, textToSend: textToSend)
                    }
                }
                .frame(alignment: .top)
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
                        isSorted.toggle()
                    }) {
                        Text( isSorted ? "⬇️" : "💙")
                    }
                    .buttonStyle(BorderedButtonStyle())
                    Button(action: {
                        bluetoothManager.connectingChracteristic = TransferService.ID.dataUUID.uuidString
                    }) {
                        Text("📚")
                    }
                    .buttonStyle(BorderedButtonStyle())
                    Button(action: {
                        bluetoothManager.connectingChracteristic = TransferService.ID.writeUUID.uuidString
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
