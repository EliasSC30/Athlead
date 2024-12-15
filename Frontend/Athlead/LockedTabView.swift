//
//  LockedTabView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//


import SwiftUI

struct LockedTabViewLockedTabView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
                .padding()

            Text("Bitte logge dich ein, um Wettkämpfe zu sehen.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .padding()
    }
}
