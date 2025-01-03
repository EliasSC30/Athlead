//
//  ContestDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//
import SwiftUI

import CoreImage.CIFilterBuiltins

struct QRCodeGeneratorView: View {
    @State var qrString: String = ""
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        VStack(spacing: 20) {
            Text("Check-In QR Code")
                .font(.headline)

            if let qrImage = generateQRCode(from: qrString) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Text("Failed to generate QR Code")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}


struct ContestDetailView: View {
    @State var contest: ContestForJudge?
    
    var body: some View {
        
        VStack {
            if contest != nil {
                NavigationLink(destination: QRCodeGeneratorView(qrString: contest!.ct_id + ";" + (User == nil ? "": User.unsafelyUnwrapped.ID))){
                    Text("Checke für \(contest!.ct_name) ein")
                }
                .padding()
                .background(Color.white)
                .shadow(radius: 4.0)
            } else {
                Text("Kein Wettkampf")
            }
            
        }
    }
}
    
    
    

