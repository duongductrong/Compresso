import SwiftUI

enum OnboardingPreferences {
    static let isCompleteKey = "onboarding.isComplete"
}

struct CompressoLaunchView: View {
    @AppStorage(OnboardingPreferences.isCompleteKey) private var isOnboardingComplete = false

    var body: some View {
        Group {
            if isOnboardingComplete {
                ContentView()
            } else {
                OnboardingView {
                    isOnboardingComplete = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isOnboardingComplete)
    }
}
