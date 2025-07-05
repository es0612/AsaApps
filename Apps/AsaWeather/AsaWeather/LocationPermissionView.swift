import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @ObservedObject var locationManager: LocationManager
    let onPermissionGranted: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "location.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("位置情報の許可が必要です")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .multilineTextAlignment(.center)
                
                Text("現在地の天気情報を取得するために、位置情報へのアクセスを許可してください。")
                    .font(.body)
                    .foregroundColor(Color("AsaMutedSage"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    print("🔔 LocationPermissionView: 位置情報を許可ボタンが押されました")
                    locationManager.requestPermission()
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("位置情報を許可")
                    }
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AsaCoffeeBrown"))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("設定アプリで許可")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AsaSoftCream"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("AsaCoffeeBrown"), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
            
            if let errorMessage = locationManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color("AsaSoftCream").opacity(0.1))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding()
        .onChange(of: locationManager.isLocationEnabled) { _, isEnabled in
            if isEnabled {
                onPermissionGranted()
            }
        }
    }
}

struct LocationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPermissionView(
            locationManager: LocationManager(),
            onPermissionGranted: {}
        )
        .background(Color("AsaDarkSlate").opacity(0.1))
    }
}