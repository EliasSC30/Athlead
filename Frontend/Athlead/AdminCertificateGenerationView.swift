//
//  AdminCertificateGenerationView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 10.01.25.
//


import SwiftUI
import PDFKit

struct AdminCertificateGenerationView: View {
    @State private var classSelection = "1a"
    @State private var ehrenPercentage: Double = 20
    @State private var siegerPercentage: Double = 50
    @State private var teilnahmePercentage: Double = 30

    @State private var showPDF = false
    @State private var generatedPDF: PDFDocument?

    // Dummy data for ParticipantDummys
    let ParticipantDummys = [
        ParticipantDummy(name: "Alice", points: 95),
        ParticipantDummy(name: "Bob", points: 85),
        ParticipantDummy(name: "Charlie", points: 70),
        ParticipantDummy(name: "David", points: 60),
        ParticipantDummy(name: "Eve", points: 50)
    ]

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Class Selection")) {
                        Picker("Select Class", selection: $classSelection) {
                            Text("1a").tag("1a")
                            Text("1b").tag("1b")
                            Text("1c").tag("1c")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    Section(header: Text("Certificate Percentages")) {
                        HStack {
                            Text("Ehrenurkunde (%):")
                            Slider(value: $ehrenPercentage, in: 0...100, step: 1)
                            Text("\(Int(ehrenPercentage))%")
                        }

                        HStack {
                            Text("Siegerurkunde (%):")
                            Slider(value: $siegerPercentage, in: 0...100 - ehrenPercentage, step: 1)
                            Text("\(Int(siegerPercentage))%")
                        }

                        Text("Teilnahmeurkunde (%): \(Int(100 - ehrenPercentage - siegerPercentage))%")
                            .foregroundColor(.gray)
                    }
                }

                Button(action: generateCertificates) {
                    Text("Generate Certificates PDF")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Certificate Generator")
            .sheet(isPresented: $showPDF) {
                PDFViewer(pdfDocument: generatedPDF)
            }
        }
    }

    func generateCertificates() {
        let sortedParticipantDummys = ParticipantDummys.sorted { $0.points > $1.points }
        let totalParticipantDummys = ParticipantDummys.count

        let ehrenCount = Int(Double(totalParticipantDummys) * (ehrenPercentage / 100))
        let siegerCount = Int(Double(totalParticipantDummys) * (siegerPercentage / 100))
        let teilnahmeCount = totalParticipantDummys - ehrenCount - siegerCount

        let ehrenParticipantDummys = sortedParticipantDummys.prefix(ehrenCount)
        let siegerParticipantDummys = sortedParticipantDummys.dropFirst(ehrenCount).prefix(siegerCount)
        let teilnahmeParticipantDummys = sortedParticipantDummys.dropFirst(ehrenCount + siegerCount)

        let pdfData = PDFCreator.createPDF(
            className: classSelection,
            ehren: Array(ehrenParticipantDummys),
            sieger: Array(siegerParticipantDummys),
            teilnahme: Array(teilnahmeParticipantDummys)
        )

        if let pdfDocument = PDFDocument(data: pdfData) {
            self.generatedPDF = pdfDocument
            self.showPDF = true
        }
    }
}

struct ParticipantDummy {
    let name: String
    let points: Int
}

struct PDFViewer: View {
    let pdfDocument: PDFDocument?

    var body: some View {
        PDFKitRepresentedView(pdfDocument: pdfDocument)
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let pdfDocument: PDFDocument?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct PDFCreator {
    static func createPDF(className: String, ehren: [ParticipantDummy], sieger: [ParticipantDummy], teilnahme: [ParticipantDummy]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Certificate Generator",
            kCGPDFContextAuthor: "Admin"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageSize = CGSize(width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        let data = renderer.pdfData { (context) in
            context.beginPage()
            let font = UIFont.systemFont(ofSize: 16)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font
            ]

            var yPosition: CGFloat = 20
            let title = "Certificates for Class \(className)"
            title.draw(at: CGPoint(x: 20, y: yPosition), withAttributes: attributes)
            yPosition += 40

            func drawParticipantDummys(title: String, ParticipantDummys: [ParticipantDummy]) {
                title.draw(at: CGPoint(x: 20, y: yPosition), withAttributes: attributes)
                yPosition += 20

                for ParticipantDummy in ParticipantDummys {
                    let line = "\(ParticipantDummy.name) - Points: \(ParticipantDummy.points)"
                    line.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: attributes)
                    yPosition += 20
                }

                yPosition += 20
            }

            drawParticipantDummys(title: "Ehrenurkunde", ParticipantDummys: ehren)
            drawParticipantDummys(title: "Siegerurkunde", ParticipantDummys: sieger)
            drawParticipantDummys(title: "Teilnahmeurkunde", ParticipantDummys: teilnahme)
        }

        return data
    }
}

struct AdminCertificateGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        AdminCertificateGenerationView()
    }
}
