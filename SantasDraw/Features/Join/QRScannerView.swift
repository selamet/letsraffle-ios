import AVFoundation
import SwiftUI

/// Full-screen QR scanner returning the first invite code it recognises.
struct QRScannerSheet: View {
    var onCode: (String) -> Void
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @State private var authorization = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch authorization {
            case .authorized:
                QRCameraView { payload in
                    guard let code = InviteLink.code(from: payload) else { return false }
                    onCode(code)
                    dismiss()
                    return true
                }
                .ignoresSafeArea()
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white, lineWidth: 4)
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.4), radius: 10)
            case .notDetermined:
                ProgressView().tint(.white)
            default:
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill").font(.system(size: 40)).foregroundStyle(.white)
                    Text(t.cameraDenied).foregroundStyle(.white).multilineTextAlignment(.center).padding(.horizontal, 32)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link(t.preferences, destination: url).buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(16)
        }
        .task {
            if authorization == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: .video)
                authorization = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
    }
}

/// AVFoundation preview + QR metadata detection.
private struct QRCameraView: UIViewControllerRepresentable {
    /// Return `true` to stop scanning.
    var onPayload: (String) -> Bool

    func makeUIViewController(context: Context) -> ScannerController {
        let controller = ScannerController()
        controller.onPayload = onPayload
        return controller
    }

    func updateUIViewController(_ controller: ScannerController, context: Context) {
        controller.onPayload = onPayload
    }

    final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onPayload: ((String) -> Bool)?
        private let session = AVCaptureSession()
        private var preview: AVCaptureVideoPreviewLayer?
        private var finished = false

        override func viewDidLoad() {
            super.viewDidLoad()
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)
            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
            preview = layer
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            preview?.frame = view.bounds
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            let session = session
            DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            session.stopRunning()
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !finished,
                  let payload = (objects.first as? AVMetadataMachineReadableCodeObject)?.stringValue,
                  onPayload?(payload) == true else { return }
            finished = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            session.stopRunning()
        }
    }
}
