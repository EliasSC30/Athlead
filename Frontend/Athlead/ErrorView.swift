//
//  ErrorView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 29.11.24.
//

import SwiftUI

struct ErrorView : View {
    let errorSource : String = "Error Source was not set"
    var body: some View {
        Text("Something went wrong coming from " + errorSource)
    }
}
