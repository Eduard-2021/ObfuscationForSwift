//
//  ProgressOfLoad.swift
//  Obfuscare
//
//  Created by Macintosh HD on 14.07.2025.
//

import SwiftUI

struct ProgressOfLoad: View {
    var height: CGFloat
    var color: Color
    
    var body: some View {
        VStack{
            Spacer()
            ProgressView()
                .scaleEffect(1.5, anchor: .center)
                .colorInvert()
            Spacer()
        }
        .frame(height: height)
    }
}
