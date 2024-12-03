//
//  ContactPersonCard.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//
import SwiftUI

struct ContactPersonCard: View {
    var firstName: String
    var lastName: String
    var phone: String
    var email: String
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                // Generic Icon
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
                
                // Name and Contact Info
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(firstName) \(lastName)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                        Text(phone)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.orange)
                        Text(email)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 20)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}
