import SwiftUI
import Photos

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            privacyPage.tag(1)
            permissionPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to ScreenStash")
                .font(.largeTitle.bold())

            Text("Finally organize the screenshot chaos in your photo library.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button("Get Started") {
                withAnimation { currentPage = 1 }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer().frame(height: 60)
        }
    }

    private var privacyPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("100% Private")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 16) {
                privacyItem(icon: "cpu", text: "All OCR runs on your device")
                privacyItem(icon: "icloud.slash.fill", text: "No data uploaded to any cloud")
                privacyItem(icon: "photo.on.rectangle", text: "Screenshots stay in your Photos library")
                privacyItem(icon: "eye.slash.fill", text: "We never see your screenshots")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("Continue") {
                withAnimation { currentPage = 2 }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer().frame(height: 60)
        }
    }

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.badge.checkmark.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("Photo Library Access")
                .font(.largeTitle.bold())

            Text("ScreenStash needs access to your photos to find and organize your screenshots.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            if authorizationStatus == .authorized || authorizationStatus == .limited {
                Button("Let's Go!") {
                    hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button("Allow Photo Access") {
                    requestPhotoAccess()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer().frame(height: 60)
        }
    }

    private func privacyItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 28)
            Text(text)
                .font(.body)
        }
    }

    private func requestPhotoAccess() {
        Task {
            let status = await ScreenshotImporter.requestAuthorization()
            await MainActor.run {
                authorizationStatus = status
                if status == .authorized || status == .limited {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
