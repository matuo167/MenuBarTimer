import AppKit
import Combine
import SwiftUI

@MainActor
final class TimerModel: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var hasStarted = false
    @Published private(set) var isAlarmActive = false
    @Published private(set) var remainingSeconds = 1_500

    @Published var inputHours = 0 {
        didSet { refreshCountdownPreview() }
    }

    @Published var inputMinutes = 25 {
        didSet { refreshCountdownPreview() }
    }

    @Published var inputSeconds = 0 {
        didSet { refreshCountdownPreview() }
    }

    private var timer: Timer?
    private var alarmStopTimer: Timer?

    var formattedDisplay: String {
        Self.format(seconds: remainingSeconds)
    }

    var menuBarDisplay: String {
        Self.formatCompact(seconds: remainingSeconds)
    }

    var shouldShowMenuBarTime: Bool {
        hasStarted
    }

    var primaryButtonTitle: String {
        if isAlarmActive { return "音を止める" }
        return isRunning ? "一時停止" : "開始"
    }

    var primaryButtonImageName: String {
        if isAlarmActive { return "speaker.slash.fill" }
        return isRunning ? "pause.fill" : "play.fill"
    }

    var statusText: String {
        if isRunning { return "残り時間" }
        if isAlarmActive { return "音を再生中" }
        if hasStarted && remainingSeconds == 0 { return "完了" }
        if hasStarted { return "一時停止中" }
        return "待機中"
    }

    private var configuredSeconds: Int {
        (inputHours * 3_600) + (inputMinutes * 60) + inputSeconds
    }

    func toggleRunning() {
        if isAlarmActive {
            stopAlarm()
            return
        }

        isRunning ? pause() : start()
    }

    func start() {
        stopAlarm()

        if remainingSeconds == 0 {
            remainingSeconds = configuredSeconds
        }
        guard remainingSeconds > 0 else { return }

        guard !isRunning else { return }
        hasStarted = true
        isRunning = true
        scheduleTimer()
    }

    func pause() {
        isRunning = false
        invalidateTimer()
    }

    func reset() {
        isRunning = false
        hasStarted = false
        stopAlarm()
        invalidateTimer()
        remainingSeconds = configuredSeconds
    }

    private func refreshCountdownPreview() {
        guard !isRunning else { return }
        stopAlarm()
        hasStarted = false
        remainingSeconds = configuredSeconds
    }

    private func scheduleTimer() {
        invalidateTimer()

        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isRunning else { return }

        remainingSeconds = max(remainingSeconds - 1, 0)
        if remainingSeconds == 0 {
            pause()
            startAlarm()
        }
    }

    private func startAlarm() {
        alarmStopTimer?.invalidate()
        isAlarmActive = true
        TimerSoundPlayer.shared.startRepeatingFinishedSound()

        let newTimer = Timer(timeInterval: 30.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopAlarm()
            }
        }

        alarmStopTimer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    private func stopAlarm() {
        alarmStopTimer?.invalidate()
        alarmStopTimer = nil

        guard isAlarmActive else { return }
        isAlarmActive = false
        TimerSoundPlayer.shared.stopRepeatingFinishedSound()
    }

    private static func format(seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3_600
        let minutes = (safeSeconds % 3_600) / 60
        let seconds = safeSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private static func formatCompact(seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3_600
        let minutes = (safeSeconds % 3_600) / 60
        let seconds = safeSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TimerPanelView: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .withinWindow)

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text("タイマー")
                        .font(.system(.headline, weight: .semibold))

                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .glassSurface(cornerRadius: 14)

                Text(model.formattedDisplay)
                    .font(.system(size: 42, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .glassSurface(cornerRadius: 22, opacity: 0.28)

                HStack(spacing: 8) {
                    TimeUnitInput(
                        title: "時間",
                        value: $model.inputHours,
                        range: 0...99,
                        isDisabled: model.isRunning
                    )

                    TimeUnitInput(
                        title: "分",
                        value: $model.inputMinutes,
                        range: 0...59,
                        isDisabled: model.isRunning
                    )

                    TimeUnitInput(
                        title: "秒",
                        value: $model.inputSeconds,
                        range: 0...59,
                        isDisabled: model.isRunning
                    )
                }

                HStack(spacing: 10) {
                    Button(action: model.toggleRunning) {
                        Label(model.primaryButtonTitle, systemImage: model.primaryButtonImageName)
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(GlassButtonStyle(isProminent: true))

                    Button(action: model.reset) {
                        Label("リセット", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                }

                Rectangle()
                    .fill(.white.opacity(0.18))
                    .frame(height: 1)

                HStack(spacing: 10) {
                    Text(model.statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "power")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(GlassIconButtonStyle())
                    .help("終了")
                }
            }
            .padding(18)
        }
        .frame(width: 350)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.20), radius: 24, x: 0, y: 14)
        .padding(8)
    }
}

struct TimeUnitInput: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let isDisabled: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Button {
                    value = max(range.lowerBound, value - 1)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .disabled(isDisabled || value <= range.lowerBound)
                .help("\(title)を減らす")

                TextField("", value: clampedValue, format: .number)
                    .font(.system(.title3, design: .monospaced))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(width: 48)
                    .padding(.vertical, 7)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.white.opacity(0.20))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.white.opacity(0.24), lineWidth: 1)
                    }
                    .disabled(isDisabled)

                Button {
                    value = min(range.upperBound, value + 1)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .disabled(isDisabled || value >= range.upperBound)
                .help("\(title)を増やす")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .glassSurface(cornerRadius: 18)
    }

    private var clampedValue: Binding<Int> {
        Binding(
            get: { value },
            set: { newValue in
                value = min(max(newValue, range.lowerBound), range.upperBound)
            }
        )
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 28
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}

struct GlassButtonStyle: ButtonStyle {
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(isProminent ? .white : .primary)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(background(configuration: configuration))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(.white.opacity(isProminent ? 0.38 : 0.26), lineWidth: 1)
            }
            .shadow(color: shadowColor.opacity(configuration.isPressed ? 0.08 : 0.18), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }

    private var shadowColor: Color {
        isProminent ? .blue : .black
    }

    private func background(configuration: Configuration) -> AnyShapeStyle {
        if isProminent {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        .cyan.opacity(configuration.isPressed ? 0.42 : 0.58),
                        .blue.opacity(configuration.isPressed ? 0.46 : 0.64)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(.white.opacity(configuration.isPressed ? 0.20 : 0.14))
    }
}

struct GlassIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.secondary)
            .background {
                Circle()
                    .fill(.white.opacity(configuration.isPressed ? 0.22 : 0.14))
            }
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private extension View {
    func glassSurface(cornerRadius: CGFloat, opacity: Double = 0.16) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.white.opacity(opacity))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
    }
}

@MainActor
final class TimerSoundPlayer: NSObject, NSSoundDelegate {
    static let shared = TimerSoundPlayer()

    private var finishedSound: NSSound?
    private var repeatTimer: Timer?

    private override init() {
        super.init()
        finishedSound = Self.makeFinishedSound()
        finishedSound?.delegate = self
    }

    func startRepeatingFinishedSound() {
        stopRepeatingFinishedSound()
        playFinishedSound()

        let newTimer = Timer(timeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playFinishedSound()
            }
        }

        repeatTimer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    func stopRepeatingFinishedSound() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        finishedSound?.stop()
    }

    private func playFinishedSound() {
        guard let sound = finishedSound else {
            NSSound.beep()
            return
        }

        sound.stop()
        sound.currentTime = 0
        sound.volume = 1.0

        if !sound.play() {
            NSSound.beep()
        }
    }

    private static func makeFinishedSound() -> NSSound? {
        let systemSoundPath = "/System/Library/Sounds/Glass.aiff"

        if FileManager.default.fileExists(atPath: systemSoundPath) {
            return NSSound(contentsOfFile: systemSoundPath, byReference: true)
        }

        return NSSound(named: NSSound.Name("Glass"))
    }
}

@MainActor
final class StatusBarController: NSObject {
    private let model: TimerModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var modelUpdates: AnyCancellable?

    init(model: TimerModel) {
        self.model = model
        super.init()

        configureStatusItem()
        configurePopover()
        observeTimer()
        updateStatusItem()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "タイマー")
        image?.isTemplate = true

        button.image = image
        button.imagePosition = .imageLeft
        button.target = self
        button.action = #selector(togglePopover)
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 366, height: 360)
        popover.contentViewController = NSHostingController(rootView: TimerPanelView(model: model))
    }

    private func observeTimer() {
        modelUpdates = Publishers.CombineLatest(model.$remainingSeconds, model.$hasStarted).sink { [weak self] _, _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }

        button.title = model.shouldShowMenuBarTime ? " \(model.menuBarDisplay)" : ""
        statusItem.length = NSStatusItem.variableLength
    }

    func showPopover() {
        guard let button = statusItem.button else { return }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = TimerModel()
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        statusBarController = StatusBarController(model: model)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusBarController?.showPopover()
        return true
    }
}

@main
struct MenuBarTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
