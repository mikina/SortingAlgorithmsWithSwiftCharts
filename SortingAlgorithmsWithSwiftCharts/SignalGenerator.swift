import AVFoundation
import Foundation

class Beep {
    var mixer: AVAudioMixerNode?
    var timer = Timer()
    var timerStart = Timer()
    let engine = AVAudioEngine()
    
    func beep(_ frequency: Int) {
        let frequency = Float(frequency) * Float(frequency) + 800
        let amplitude = Float(1)
        let duration = 0.05
        
        let twoPi = 2 * Float.pi
        
        let sine = { (phase: Float) -> Float in
            sin(phase)
        }
        
        var signal: (Float) -> Float
        
        signal = sine
        
        let mainMixer = engine.mainMixerNode
        mixer = mainMixer
        let output = engine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let sampleRate = Float(outputFormat.sampleRate)
        // Use the output format for the input, but reduce the channel count to 1.
        let inputFormat = AVAudioFormat(commonFormat: outputFormat.commonFormat,
                                        sampleRate: outputFormat.sampleRate,
                                        channels: 1,
                                        interleaved: outputFormat.isInterleaved)
        
        var currentPhase: Float = 0
        // The interval to advance the phase each frame.
        let phaseIncrement = (twoPi / sampleRate) * frequency
        
        let srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0 ..< Int(frameCount) {
                // Get the signal value for this frame at time.
                let value = signal(currentPhase) * amplitude
                // Advance the phase for the next frame.
                currentPhase += phaseIncrement
                if currentPhase >= twoPi {
                    currentPhase -= twoPi
                }
                if currentPhase < 0.0 {
                    currentPhase += twoPi
                }
                // Set the same value on all channels (due to the inputFormat, there's only one channel though).
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = value
                }
            }
            return noErr
        }
        
        engine.attach(srcNode)
        
        engine.connect(srcNode, to: mainMixer, format: inputFormat)
        engine.connect(mainMixer, to: output, format: outputFormat)
        mainMixer.outputVolume = 0.15
        
        do {
            try engine.start()
            CFRunLoopRunInMode(.defaultMode, CFTimeInterval(duration), false)
            timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(process), userInfo: index, repeats: true)
        } catch {
            print("Could not start engine: \(error)")
        }
    }
    
    @objc private func process(_ timer: Timer) {
        guard let mixer else {
            return
        }
        
        mixer.outputVolume = mixer.outputVolume * 0.9
        
        if mixer.outputVolume <= 0.009 {
            timer.invalidate()
            engine.stop()
        }
    }
}

func beep(_ frequency: Int) {
    let beep = Beep()
    beep.beep(frequency)
}
