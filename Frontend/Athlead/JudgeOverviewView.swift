//
//  JudgeOverviewView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 30.11.24.
//

import SwiftUI


struct JudgeOverviewView : View {
    let competitions = ["100m Lauf", "Weitsprung", "Hochsprung"]
    
    var body: some View {
        HStack {
            NavigationView {
                ScrollView {
                    Section(header: Text("Eingetragene Ergebnisse").font(.headline)) {
                        
                        ForEach(competitions.indices, id: \.self) { index in
                            Text(competitions[index])
                            NavigationLink("\(competitions[index])", destination: JudgeContestView(COMPETITION: competitions[index]))
                        }
                    }
                }
            }
        }
    }
}
