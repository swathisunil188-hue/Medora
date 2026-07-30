import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var scale = 0.7
    @State private var opacity = 0.5

    var body: some View {
        if isActive {
            RootRouterView()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.blue, Color.teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "cross.case.fill")
                        .resizable().scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                        .opacity(opacity)

                    Text("MediVerify AI")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(opacity)

                    Text("Your AI Prescription Companion")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(opacity)

                    ProgressView()
                        .tint(.white)
                        .padding(.top, 20)
                        .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    scale = 1.0
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

struct RootRouterView: View {
    var body: some View {
        if LocalStorageService.shared.getCurrentUser() != nil {
            HomeDashboardView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    SplashScreenView()
}
//  splashscreenview.swift
//  medora
//
//  Created by STUDENT_24 on 30/07/26.
//


