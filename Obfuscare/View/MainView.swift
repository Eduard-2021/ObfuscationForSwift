//
//  ContentView.swift
//  Obfuscare
//
//  Created by Macintosh HD on 14.07.2025.
//

import SwiftUI

struct MainView: View {
    
    @StateObject var mainViewModel = MainViewModel()
    
    var body: some View {
        VStack {
            Button {
                mainViewModel.runObfuscation()
            } label: {
                Text("Start")
                    .foregroundColor(.white)
                    .frame(width: Constants.widthOfButton)
                    .font(.callout.bold())
                    .padding(.vertical, Constants.heightOfMainButtons)
                    .background(.blue)
            }
            
            if mainViewModel.isProgressViewShow {
                ProgressOfLoad(height: Constants.heightOfProgressView, color: .white)
            }
            
        }
        .alert(mainViewModel.messageOfAlert, isPresented: $mainViewModel.isShowAlert) {
            Text("Error")
                .foregroundColor(.white)
                .frame(width: Constants.widthOfButton)
                .font(.callout.bold())
                .padding(.vertical, Constants.heightOfMainButtons)
                .background(.blue)
        }
        .padding()
    }
}

