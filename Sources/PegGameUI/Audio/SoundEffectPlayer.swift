import AVFoundation
import Foundation

/// Plays short procedurally-generated sound effects for game events.
///
/// All buffers are pre-baked at init so `play(_:)` is allocation-free at
/// the call site. AVAudioSession is set to `.ambient` so the game doesn't
/// interrupt music a user might already be playing — sound effects mix in
/// over whatever else is going.
///
/// Procedural synthesis is intentional: it keeps the package self-contained
/// (no audio assets to bundle, version, or license).
@MainActor
final class SoundEffectPlayer {

    enum Effect: Hashable, Sendable {
        case pegSelect    // tap a peg to choose it — short blip
        case pegMove      // peg lands at destination — wooden thunk
        case hint         // hint shown — light chime
        case undo         // last move reversed — descending blip
        case win          // game complete — ascending arpeggio
    }

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private var didStart = false

    init() {
        // Mono 44.1kHz Float32 — plenty for short percussive SFX.
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else {
            self.format = AVAudioFormat()
            return
        }
        self.format = format

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)

        buffers[.pegSelect] = Self.makeSine(format: format, frequency: 540, duration: 0.07, decay: 16, volume: 0.32)
        buffers[.pegMove]   = Self.makeThunk(format: format, duration: 0.15)
        buffers[.hint]      = Self.makeChime(format: format)
        buffers[.undo]      = Self.makeSine(format: format, frequency: 380, duration: 0.10, decay: 12, volume: 0.28)
        buffers[.win]       = Self.makeArpeggio(
            format: format,
            frequencies: [523.25, 659.25, 783.99, 1046.50],   // C5 E5 G5 C6
            noteDuration: 0.14
        )

        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            try engine.start()
            playerNode.play()
            didStart = true
        } catch {
            // Best-effort: if audio init fails we just go silent.
        }
    }

    /// Play `effect`. No-op if the engine never started or the buffer is missing.
    func play(_ effect: Effect) {
        guard didStart, let buffer = buffers[effect] else { return }
        // `.interrupts` cancels any pending scheduled buffers so rapid-fire
        // events (e.g., undo spam) don't queue up audio backlog.
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }

    // MARK: - Buffer generators

    private static func makeSine(
        format: AVAudioFormat,
        frequency: Float,
        duration: TimeInterval,
        decay: Float,
        volume: Float
    ) -> AVAudioPCMBuffer? {
        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(duration * Double(sampleRate))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Float(i) / sampleRate
            let envelope = exp(-t * decay)
            data[i] = sin(2 * .pi * frequency * t) * envelope * volume
        }
        return buffer
    }

    private static func makeThunk(format: AVAudioFormat, duration: TimeInterval) -> AVAudioPCMBuffer? {
        // Lowpass-filtered noise + a low-frequency body for a wooden landing sound.
        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(duration * Double(sampleRate))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        var prev: Float = 0
        let alpha: Float = 0.08
        for i in 0..<Int(frameCount) {
            let t = Float(i) / sampleRate
            let envelope = exp(-t * 22)
            let noise = Float.random(in: -1...1)
            prev = alpha * noise + (1 - alpha) * prev
            let body = sin(2 * .pi * 140 * t) * 0.32
            data[i] = (prev * 0.68 + body) * envelope * 0.58
        }
        return buffer
    }

    private static func makeChime(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // Two stacked sines for a chimey hint indication.
        let sampleRate = Float(format.sampleRate)
        let duration: TimeInterval = 0.18
        let frameCount = AVAudioFrameCount(duration * Double(sampleRate))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Float(i) / sampleRate
            let envelope = exp(-t * 10)
            let fundamental = sin(2 * .pi * 880 * t)
            let third = sin(2 * .pi * 1318.5 * t) * 0.42
            data[i] = (fundamental + third) * envelope * 0.28
        }
        return buffer
    }

    private static func makeArpeggio(
        format: AVAudioFormat,
        frequencies: [Float],
        noteDuration: TimeInterval
    ) -> AVAudioPCMBuffer? {
        let sampleRate = Float(format.sampleRate)
        let noteFrames = Int(noteDuration * Double(sampleRate))
        let totalFrames = AVAudioFrameCount(noteFrames * frequencies.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
            return nil
        }
        buffer.frameLength = totalFrames
        let data = buffer.floatChannelData![0]
        for (idx, frequency) in frequencies.enumerated() {
            for i in 0..<noteFrames {
                let t = Float(i) / sampleRate
                // Quick attack, exponential release per note.
                let envelope = exp(-t * 8) * (1 - exp(-t * 80))
                data[idx * noteFrames + i] = sin(2 * .pi * frequency * t) * envelope * 0.38
            }
        }
        return buffer
    }
}
