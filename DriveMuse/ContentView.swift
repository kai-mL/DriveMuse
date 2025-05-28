<<<<<<< HEAD

import SwiftUI
import MapKit

struct ContentView: View {
    
    @State private var region = MKCoordinateRegion(
            //Mapの中心の緯度経度
            center: CLLocationCoordinate2D(latitude: 35.6585,
                                           longitude: 139.7013),
            //緯度の表示領域(m)
            latitudinalMeters: 750,
            //経度の表示領域(m)
            longitudinalMeters: 750
    )
    var body: some View {
        Map(coordinateRegion: $region,
            //Mapの操作の指定
            interactionModes: .pan,
            //現在地の表示
            showsUserLocation: true,
            //現在地の追従
            userTrackingMode: .constant(MapUserTrackingMode.follow)
        )
        .task(){
            //位置情報へのアクセスを要求
            let manager = CLLocationManager()
            manager.requestWhenInUseAuthorization()
        }
    }
}
=======
// SwiftUI + MapKit + Speech Recognition + Gemini 2.0 Flash 統合版
import SwiftUI
import MapKit
import Speech
import AVFoundation

// MARK: - GeminiService: Google Gemini Flash API 呼び出し
class GeminiService: ObservableObject {
    static let shared = GeminiService()
    @Published var responseText: String = ""
    private let apiKey = "AIzaSyAmYOHti7xwpIch95mL1aEyb0gQcUNPTjc"
    private let model = "gemini-2.0-flash"

    func sendToGemini(_ text: String) async {
        // 空文字チェック
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        print("➡️ Sending to Gemini with text:", trimmed)

        // URL と認証ヘッダー
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // リクエストボディ: Quickstart 仕様に準拠
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": trimmed]
                    ]
                ]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let raw = String(data: data, encoding: .utf8) ?? ""
            print("🌐 Gemini raw response: \(raw)")

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let contentObj = first["content"] as? [String: Any],
               let parts = contentObj["parts"] as? [[String: Any]],
               let part0 = parts.first,
               let text = part0["text"] as? String {
                await MainActor.run {
                    self.responseText = text
                    print("✅ Parsed Gemini reply:", text)
                }
            } else {
                print("❗️ Failed to parse Gemini response structure.")
            }
        } catch {
            print("❗️ Gemini API error:", error)
        }

    }
}

// MARK: - SpeechRecognizer: 音声入力と認識を管理するクラス
class SpeechRecognizer: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecording = false
    @Published var transcriptLog: [String] = []
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { self.authorizationStatus = status }
        }
    }

    func startRecording() {
        guard authorizationStatus == .authorized,
              let recognizer = speechRecognizer, recognizer.isAvailable,
              !audioEngine.isRunning else { return }
        recognizedText = ""

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        recognitionTask = recognizer.recognitionTask(with: request!) { result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = text
                    if result.isFinal {
                        // 空文字でなければ送信
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            self.transcriptLog.append(trimmed)
                            print("🎙 Final recognized text:", trimmed)
                            print("➡️ About to send to Gemini")
                            Task { await GeminiService.shared.sendToGemini(trimmed) }
                        }
                    }
                }
            }
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
        DispatchQueue.main.async { self.isRecording = true }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        // ➡️ ここでは cancel しない
        // recognitionTask?.cancel()
        DispatchQueue.main.async { self.isRecording = false }
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // 必要なら、最終的にタスクを破棄するメソッドを別に用意
    func cleanUpRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }

}
// MARK: - TouristMapView: MapKit表示部分（変更なし）
struct TouristMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        mapView.setRegion(region, animated: false)
        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        let categories: [MKPointOfInterestCategory] = [.amusementPark, .aquarium, .beach, .campground, .castle, .fairground, .fortress, .nationalMonument, .nationalPark, .planetarium, .spa, .zoo]
        config.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
        mapView.preferredConfiguration = config
        let station = MKPointAnnotation()
        station.coordinate = CLLocationCoordinate2D(latitude: 35.6585, longitude: 139.7013)
        station.title = "渋谷駅"
        mapView.addAnnotation(station)
        context.coordinator.searchRestaurants()
        return mapView
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
    }
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TouristMapView
        weak var mapView: MKMapView?
        init(_ parent: TouristMapView) { self.parent = parent }
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
            searchRestaurants()
        }
        func searchRestaurants() {
            guard let mapView = mapView else { return }
            let old = mapView.annotations.filter { $0.subtitle??.hasPrefix("評価:") ?? false }
            mapView.removeAnnotations(old)
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = "レストラン"
            req.region = mapView.region
            MKLocalSearch(request: req).start { resp, _ in
                guard let items = resp?.mapItems else { return }
                let results = items.sorted {
                    MKMapPoint($0.placemark.coordinate).distance(to: MKMapPoint(mapView.centerCoordinate)) <
                    MKMapPoint($1.placemark.coordinate).distance(to: MKMapPoint(mapView.centerCoordinate))
                }.prefix(5)
                for item in results {
                    let ann = MKPointAnnotation()
                    ann.coordinate = item.placemark.coordinate
                    ann.title = item.name
                    let dist = MKMapPoint(mapView.centerCoordinate).distance(to: MKMapPoint(item.placemark.coordinate))
                    let rating = max(1.0, 5.0 - dist / 1000.0)
                    ann.subtitle = String(format: "評価: %.1f ⭐️", rating)
                    mapView.addAnnotation(ann)
                }
            }
        }
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let id = annotation.title == "渋谷駅" ? "station" : "restaurant"
            if id == "station" {
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKPinAnnotationView
                if view == nil {
                    view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
                    view?.pinTintColor = .red; view?.canShowCallout = true
                } else { view?.annotation = annotation }
                return view
            } else {
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                    view?.glyphText = "🍴"; view?.markerTintColor = .orange; view?.canShowCallout = true
                } else { view?.annotation = annotation }
                return view
            }
        }
    }
}

// MARK: - ContentView: 地図 + 音声 + Geminiレスポンス
struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6585, longitude: 139.7013),
        latitudinalMeters: 1000, longitudinalMeters: 1000
    )
    @StateObject private var speech = SpeechRecognizer()
    @StateObject private var gemini = GeminiService.shared
    
    // 読み上げ用シンセサイザーを保持
    @State private var synthesizer = AVSpeechSynthesizer()

    var body: some View {
            ZStack(alignment: .bottomTrailing) {
                TouristMapView(region: $region)
                    .ignoresSafeArea()

                VStack(alignment: .trailing, spacing: 12) {
                    if !gemini.responseText.isEmpty {
                        Text("Gemini: \(gemini.responseText)")
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                    }
                    if speech.isRecording {
                        Text(speech.recognizedText)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                    }
                    Button(action: {
                        speech.isRecording ? speech.stopRecording() : speech.startRecording()
                    }) {
                        Label(speech.isRecording ? "録音停止" : "話す", systemImage: speech.isRecording ? "mic.fill" : "mic")
                            .font(.title2).padding()
                            .background(speech.isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white).clipShape(Capsule())
                    }
                    .padding(.bottom, 20)
                }
                .padding(.trailing, 20)
            }
            // gemini.responseText が変わったら読み上げる
            .onChange(of: gemini.responseText) { newText in
                // 1) AVAudioSession を再生モードに
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, mode: .default)
                try? session.setActive(true)

                // 2) 読み上げ用の Utterance を作成
                let utterance = AVSpeechUtterance(string: newText)
                utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate

                // 3) 読み上げ開始
                synthesizer.speak(utterance)
            }

    }
}

>>>>>>> ponyo
