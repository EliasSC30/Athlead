//
//  JudgeOverviewView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 30.11.24.
//

import SwiftUI

struct JudgeOverviewView: View {
    let contests: [Contest] = [];
    var body: some View {
        NavigationView {
            VStack {
                JudgeContestsView()
            }
        }
    }
}
