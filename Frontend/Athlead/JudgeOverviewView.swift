//
//  JudgeOverviewView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 30.11.24.
//

import SwiftUI

struct JudgeOverviewView: View {
    let competitions = ["100m Lauf", "Weitsprung", "Hochsprung"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Title
                    Text("Wettkämpfe")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    // Competition List
                    ForEach(competitions.indices, id: \.self) { index in
                        NavigationLink(destination: JudgeContestView(COMPETITION: competitions[index])) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(competitions[index])
                                        .font(.headline)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                   
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            .padding(.horizontal)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 10)
            }
        }
    }
}
