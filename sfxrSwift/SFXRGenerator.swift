/**
 Copyright (c) 2007 Tomas Pettersson
               2016 Yohei Yoshihara
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import AudioToolbox
import AVFoundation

enum WaveType: Int, RawRepresentable {
  case square = 0
  case sawtooth = 1
  case sine = 2
  case noise = 3
}
let maxWaveTypeRawValue = WaveType.noise.rawValue

enum GeneratorType: Int {
  case pickupCoin = 0
  case laserShoot = 1
  case explosion = 2
  case powerup = 3
  case hitHurt = 4
  case jump = 5
  case blipSelect = 6
}
let maxGeneratorTypeRawValue = GeneratorType.blipSelect.rawValue

func rnd(_ range: Int) -> Int {
  return Int(arc4random_uniform(UInt32(range) + 1))
}

func frnd(_ range: Float) -> Float {
  return Float(arc4random_uniform(10000)) / Float(10000) * range
}

func brnd() -> Bool {
  return rnd(1) == 1
}

class Parameters : CustomStringConvertible {
  var waveType: WaveType = .square
  var soundVol: Float = 0.5
  var masterVol: Float = 0.05
  
  var baseFreq: Float = 0.3
  var freqLimit: Float = 0.0
  var freqRamp: Float = 0.0 // bipolar
  var freqDramp: Float = 0.0 // bipolar
  var duty: Float = 0.0
  var dutyRamp: Float = 0.0 // bipolar
  
  var vibStrength: Float = 0.0
  var vibSpeed: Float = 0.0
  var vibDelay: Float = 0.0
  
  var envAttack: Float = 0.0
  var envSustain: Float = 0.3
  var envDecay: Float = 0.4
  var envPunch: Float = 0.0
  
  var filterOn: Bool = false
  var lpfResonance: Float = 0.0
  var lpfFreq: Float = 1.0
  var lpfRamp: Float = 0.0 // bipolar
  var hpfFreq: Float = 0.0
  var hpfRamp: Float = 0.0 // bipolar
  
  var phaOffset: Float = 0.0 // bipolar
  var phaRamp: Float = 0.0 // bipolar
  
  var repeatSpeed: Float = 0.0
  
  var arpSpeed: Float = 0.0
  var arpMod: Float = 0.0 // bipolar
  
  func reset() {
    baseFreq = 0.3
    freqLimit = 0.0
    freqRamp = 0.0
    freqDramp = 0.0
    duty = 0.0
    dutyRamp = 0.0
    
    vibStrength = 0.0
    vibSpeed = 0.0
    vibDelay = 0.0
    
    envAttack = 0.0
    envSustain = 0.3
    envDecay = 0.4
    envPunch = 0.0
    
    filterOn = false
    lpfResonance = 0.0
    lpfFreq = 1.0
    lpfRamp = 0.0
    hpfFreq = 0.0
    hpfRamp = 0.0
    
    phaOffset = 0.0
    phaRamp = 0.0
    
    repeatSpeed = 0.0
    
    arpSpeed = 0.0
    arpMod = 0.0
  }
  
  var description: String {
    return "baseFreq=\(baseFreq), freqLimit=\(freqLimit), freqRamp=\(freqRamp), " +
    "freqDramp=\(freqDramp), duty=\(duty), dutyRamp=\(dutyRamp), vibStrength=\(vibStrength), " +
    "vibSpeed=\(vibSpeed), vibDelay=\(vibDelay), envAttack=\(envAttack), envSustain=\(envSustain), " +
    "envDecay=\(envDecay), envPunch=\(envPunch), filterOn=\(filterOn), lpfResonance=\(lpfResonance), " +
    "lpfFreq=\(lpfFreq), lpfRamp=\(lpfRamp), hpfFreq=\(hpfFreq), hpfRamp=\(hpfRamp), " +
    "phaOffset=\(phaOffset), phaRamp=\(phaRamp), repeatSpeed=\(repeatSpeed), arpSpeed=\(arpSpeed), " +
    "arpMod=\(arpMod)"
  }
}

class SFXRGenerator {
  private var p = Parameters()
  
  var parameters: Parameters {
    get {
      return self.p
    }
    set {
      self.p = newValue
    }
  }
  
  var playingSample = false
  
  var phase: Int = 0
  var fperiod: Double = 0.0
  var fmaxperiod: Double = 0.0
  var fslide: Double = 0.0
  var fdslide: Double = 0.0
  var period: Int = 0
  var squareDuty: Float = 0.0
  var squareSlide: Float = 0.0
  var envStage: Int = 0
  var envTime: Int = 0
  var envLength: [Int] = [0, 0, 0]
  var envVol: Float = 0.0
  var fphase: Float = 0.0
  var fdphase: Float = 0.0
  var iphase: Int = 0
  var phaserBuffer = [Float](repeating: 0.0, count: 1024)
  var ipp: Int = 0
  var noiseBuffer = [Float](repeating: 0.0, count: 32)
  var fltp: Float = 0.0
  var fltdp: Float = 0.0
  var fltw: Float = 0.0
  var fltwD: Float = 0.0
  var fltdmp: Float = 0.0
  var fltphp: Float = 0.0
  var flthp: Float = 0.0
  var flthpD: Float = 0.0
  var vibPhase: Float = 0.0
  var vibSpeed: Float = 0.0
  var vibAmp: Float = 0.0
  var repTime: Int = 0
  var repLimit: Int = 0
  var arpTime: Int = 0
  var arpLimit: Int = 0
  var arpMod: Double = 0.0
  
  var wavBits: Int = 16
  var wavFreq: Int = 44100
  
  var filesample: Float = 0.0
  var fileacc: Int = 0
  
  var muteStream: Bool = false
  
  var ioUnit: AUAudioUnit?
  
  func random() {
    p.baseFreq = pow(frnd(2.0) - 1.0, 2.0)
    if brnd() {
      p.baseFreq = pow(frnd(2.0) - 1.0, 3.0) + 0.5
    }
    p.freqLimit = 0.0
    p.freqRamp = pow(frnd(2.0) - 1.0, 5.0)
    if p.baseFreq > 0.7 && p.freqRamp > 0.2 {
      p.freqRamp = -p.freqRamp
    }
    if p.baseFreq < 0.2 && p.freqRamp < -0.05 {
      p.freqRamp = -p.freqRamp
    }
    p.freqDramp = pow(frnd(2.0) - 1.0, 3.0)
    p.duty = frnd(2.0) - 1.0
    p.dutyRamp = pow(frnd(2.0) - 1.0, 3.0)
    p.vibStrength = pow(frnd(2.0) - 1.0, 3.0)
    p.vibSpeed = frnd(2.0) - 1.0
    p.vibDelay = frnd(2.0) - 1.0
    p.envAttack = pow(frnd(2.0) - 1.0, 3.0)
    p.envSustain = pow(frnd(2.0) - 1.0, 2.0)
    p.envDecay = frnd(2.0) - 1.0
    p.envPunch = pow(frnd(0.8), 2.0)
    if p.envAttack + p.envSustain + p.envDecay < 0.2 {
      p.envSustain += 0.2 + frnd(0.3)
      p.envDecay += 0.2 + frnd(0.3)
    }
    p.lpfResonance = frnd(2.0) - 1.0
    p.lpfFreq = 1.0 - pow(frnd(1.0), 3.0)
    p.lpfRamp = pow(frnd(2.0) - 1.0, 3.0)
    if p.lpfFreq < 0.1 && p.lpfRamp < -0.05 {
      p.lpfRamp = -p.lpfRamp
    }
    p.hpfFreq = pow(frnd(1.0), 5.0)
    p.hpfRamp = pow(frnd(2.0) - 1.0, 5.0)
    p.phaOffset = pow(frnd(2.0) - 1.0, 3.0)
    p.phaRamp = pow(frnd(2.0) - 1.0, 3.0)
    p.repeatSpeed = frnd(2.0) - 1.0
    p.arpSpeed = frnd(2.0) - 1.0
    p.arpMod = frnd(2.0) - 1.0
  }
  
  func mutate() {
    if brnd() {
      p.baseFreq += frnd(0.1) - 0.05
    }
    //		if brnd() { p.freqLimit += frnd(0.1) - 0.05 }
    if brnd() {
      p.freqRamp += frnd(0.1) - 0.05
    }
    if brnd() {
      p.freqDramp += frnd(0.1) - 0.05
    }
    if brnd() {
      p.duty += frnd(0.1) - 0.05
    }
    if brnd() {
      p.dutyRamp += frnd(0.1) - 0.05
    }
    if brnd() {
      p.vibStrength += frnd(0.1) - 0.05
    }
    if brnd() {
      p.vibSpeed += frnd(0.1) - 0.05
    }
    if brnd() {
      p.vibDelay += frnd(0.1) - 0.05
    }
    if brnd() {
      p.envAttack += frnd(0.1) - 0.05
    }
    if brnd() {
      p.envSustain += frnd(0.1) - 0.05
    }
    if brnd() {
      p.envDecay += frnd(0.1) - 0.05
    }
    if brnd() {
      p.envPunch += frnd(0.1) - 0.05
    }
    if brnd() {
      p.lpfResonance += frnd(0.1) - 0.05
    }
    if brnd() {
      p.lpfFreq += frnd(0.1) - 0.05
    }
    if brnd() {
      p.lpfRamp += frnd(0.1) - 0.05
    }
    if brnd() {
      p.hpfFreq += frnd(0.1) - 0.05
    }
    if brnd() {
      p.hpfRamp += frnd(0.1) - 0.05
    }
    if brnd() {
      p.phaOffset += frnd(0.1) - 0.05
    }
    if brnd() {
      p.phaRamp += frnd(0.1) - 0.05
    }
    if brnd() {
      p.repeatSpeed += frnd(0.1) - 0.05
    }
    if brnd() {
      p.arpSpeed += frnd(0.1) - 0.05
    }
    if brnd() {
      p.arpMod += frnd(0.1) - 0.05
    }
  }
  
  func loadSettings(url: URL) {
    guard let data = try? Data(contentsOf: url) else {
      return
    }
    
    let bdata = BinaryData(data: data)
    var pos = 0
    let version: UInt32 = bdata.uint32(at: pos)
    pos += MemoryLayout<UInt32>.size
    
    let waveType: UInt32 = bdata.uint32(at: pos)
    if let waveType = WaveType(rawValue: Int(waveType)) {
      self.p.waveType = waveType
    } else {
      self.p.waveType = .square
    }
    pos += MemoryLayout<UInt32>.size
    
    if version == 102 {
      self.p.soundVol = bdata.float(at: pos)
      pos += MemoryLayout<Float>.size
    }
    
    self.p.baseFreq = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.freqLimit = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.freqRamp = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    if version >= 101 {
      self.p.freqDramp = bdata.float(at: pos)
      pos += MemoryLayout<Float>.size
    }
    
    self.p.duty = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.dutyRamp = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.vibStrength = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.vibSpeed = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.vibDelay = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    
    self.p.envAttack = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.envSustain = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.envDecay = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.envPunch = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    
    let filter_on: Bool = bdata.bool(at: pos)
    self.p.filterOn = filter_on
    pos += 1
    
    self.p.lpfResonance = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.lpfFreq = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.lpfRamp = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.hpfFreq = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.hpfRamp = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    
    self.p.phaOffset = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    self.p.phaRamp = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    
    self.p.repeatSpeed = bdata.float(at: pos)
    pos += MemoryLayout<Float>.size
    
    if version >= 101 {
      self.p.arpSpeed = bdata.float(at: pos)
      pos += MemoryLayout<Float>.size
      
      self.p.arpMod = bdata.float(at: pos)
      pos += MemoryLayout<Float>.size
    }
    
    Swift.print("\(p)")
  }
  
  func saveSettings(url: URL) {
    let bdata = BinaryData()
    let version: UInt32 = 102
    bdata.append(version)
    
    bdata.append(UInt32(p.waveType.rawValue))
    
    bdata.append(p.soundVol)
    bdata.append(p.baseFreq)
    bdata.append(p.freqLimit)
    bdata.append(p.freqRamp)
    bdata.append(p.freqDramp)
    bdata.append(p.duty)
    bdata.append(p.dutyRamp)
    
    bdata.append(p.vibStrength)
    bdata.append(p.vibSpeed)
    bdata.append(p.vibDelay)
    
    bdata.append(p.envAttack)
    bdata.append(p.envSustain)
    bdata.append(p.envDecay)
    bdata.append(p.envPunch)
    
    bdata.append(p.filterOn)
    bdata.append(p.lpfResonance)
    bdata.append(p.lpfFreq)
    bdata.append(p.lpfRamp)
    bdata.append(p.hpfFreq)
    bdata.append(p.hpfRamp)
    
    bdata.append(p.phaOffset)
    bdata.append(p.phaRamp)
    
    bdata.append(p.repeatSpeed)
    
    bdata.append(p.arpSpeed)
    bdata.append(p.arpMod)
    
    try? bdata.data.write(to: url)
  }
  
  func exportWAV() -> Data {
    let bdata = BinaryData()
    bdata.append("RIFF")
    bdata.append(UInt32(0)) // remaining file size
    bdata.append("WAVE")
    bdata.append("fmt ")
    bdata.append(UInt32(16)) // chunk size
    bdata.append(UInt16(1)) // compression code
    bdata.append(UInt16(1)) // channels
    bdata.append(UInt32(wavFreq)) // sample rate
    bdata.append(UInt32(wavFreq * wavBits / 8)) // bytes/sec
    bdata.append(UInt16(wavBits / 8)) // block align
    bdata.append(UInt16(wavBits)) // bits per sample
    
    bdata.append("data")
    
    bdata.append(UInt32(0)) // chunk size
    
    muteStream = true
    var fileSampleswritten = 0
    filesample = 0.0
    fileacc = 0
    playSample()
    var data = Data(count: 256 * MemoryLayout<Int16>.size)
    while playingSample {
      var framesWritten = 0
      data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
        framesWritten = synthSample(pointer: UnsafeMutablePointer(mutating: pointer.baseAddress!.assumingMemoryBound(to: Int16.self)),
                                    numberOfFrames: 256, exportWave: true)
      }
      let nbytes = framesWritten * MemoryLayout<Int16>.size
      for i in 0 ..< nbytes {
        bdata.append(data[i])
      }
      fileSampleswritten += nbytes
    }
    muteStream = false
    
    bdata.setUInt32(UInt32(bdata.data.count - 8), at: 4)
    bdata.setUInt32(UInt32(fileSampleswritten * wavBits / 8), at: 40)
    
    return bdata.data
  }
  
  func resetSample(restart: Bool) {
    if !restart {
      phase = 0
    }
    fperiod = 100.0 / (Double(p.baseFreq) * Double(p.baseFreq) + 0.001)
    period = Int(fperiod)
    fmaxperiod = 100.0 / (Double(p.freqLimit) * Double(p.freqLimit) + 0.001)
    fslide = 1.0 - pow(Double(p.freqRamp), 3.0) * 0.01
    fdslide = -pow(Double(p.freqDramp), 3.0) * 0.000001
    squareDuty = 0.5 - p.duty * 0.5
    squareSlide = -p.dutyRamp * 0.00005
    if p.arpMod >= 0.0 {
      arpMod = 1.0 - pow(Double(p.arpMod), 2.0) * 0.9
    } else {
      arpMod = 1.0 + pow(Double(p.arpMod), 2.0) * 10.0
    }
    arpTime = 0
    arpLimit = Int(pow(1.0 - p.arpSpeed, 2.0) * 20000 + 32)
    if p.arpSpeed == 1.0 {
      arpLimit = 0
    }
    if !restart {
      // reset filter
      fltp = 0.0
      fltdp = 0.0
      fltw = pow(p.lpfFreq, 3.0) * 0.1
      fltwD = 1.0 + p.lpfRamp * 0.0001
      fltdmp = 5.0 / (1.0 + pow(p.lpfResonance, 2.0) * 20.0) * (0.01 + fltw)
      if fltdmp > 0.8 {
        fltdmp = 0.8
      }
      fltphp = 0.0
      flthp = pow(p.hpfFreq, 2.0) * 0.1
      flthpD = 1.0 + p.hpfRamp * 0.0003
      // reset vibrato
      vibPhase = 0.0
      vibSpeed = pow(p.vibSpeed, 2.0) * 0.01
      vibAmp = p.vibStrength * 0.5
      // reset envelope
      envVol = 0.0
      envStage = 0
      envTime = 0
      // to avoid "divide by zero", add max(1, ...)
      envLength[0] = max(1, Int(p.envAttack * p.envAttack * 100000.0))
      envLength[1] = max(1, Int(p.envSustain * p.envSustain * 100000.0))
      envLength[2] = max(1, Int(p.envDecay * p.envDecay * 100000.0))
      
      fphase = pow(p.phaOffset, 2.0) * 1020.0
      if p.phaOffset < 0.0 {
        fphase = -fphase
      }
      fdphase = pow(p.phaRamp, 2.0) * 1.0
      if p.phaRamp < 0.0 {
        fdphase = -fdphase
      }
      iphase = abs(Int(fphase))
      ipp = 0
      for i in 0 ..< phaserBuffer.count {
        phaserBuffer[i] = 0.0
      }
      
      for i in 0 ..< noiseBuffer.count {
        noiseBuffer[i] = frnd(2.0) - 1.0
      }
      
      repTime = 0
      repLimit = Int(pow(1.0 - p.repeatSpeed, 2.0) * 20000 + 32)
      if p.repeatSpeed == 0.0 {
        repLimit = 0
      }
    }
  }
  
  func playSample() {
    resetSample(restart: false)
    playingSample = true
  }
  
  func synthSample(pointer _ptr: UnsafeMutablePointer<Int16>, numberOfFrames nframes: Int, exportWave: Bool = false) -> Int {
    var ptr = _ptr
    
    var framesWritten = 0
    for _ in 0 ..< nframes {
      if !playingSample {
        break
      }
      
      repTime += 1
      if repLimit != 0 && repTime >= repLimit {
        repTime = 0
        resetSample(restart: true)
      }
      
      // frequency envelopes/arpeggios
      arpTime += 1
      if arpLimit != 0 && arpTime >= arpLimit {
        arpLimit = 0
        fperiod *= arpMod
      }
      fslide += fdslide
      fperiod *= fslide
      if fperiod > fmaxperiod {
        fperiod = fmaxperiod
        if p.freqLimit > 0.0 {
          playingSample = false
        }
      }
      var rfperiod = fperiod
      if vibAmp > 0.0 {
        vibPhase += vibSpeed
        rfperiod = fperiod * Double(1.0 + sin(vibPhase) * vibAmp)
      }
      period = Int(rfperiod)
      if period < 8 {
        period = 8
      }
      squareDuty += squareSlide
      if squareDuty < 0.0 {
        squareDuty = 0.0
      }
      if squareDuty > 0.5 {
        squareDuty = 0.5
      }
      // volume envelope
      envTime += 1
      if envTime > envLength[envStage] {
        envTime = 0
        envStage += 1
        if envStage == 3 {
          playingSample = false
        }
      }
      if envStage == 0 {
        envVol = Float(envTime) / Float(envLength[0])
      }
      if envStage == 1 {
        envVol = 1.0 + pow(1.0 - Float(envTime) / Float(envLength[1]), 1.0) * 2.0 * p.envPunch
      }
      if envStage == 2 {
        envVol = 1.0 - Float(envTime) / Float(envLength[2])
      }
      
      // phaser step
      fphase += fdphase
      iphase = abs(Int(fphase))
      if iphase > 1023 {
        iphase = 1023
      }
      
      if flthpD != 0.0 {
        flthp *= flthpD
        if flthp < 0.00001 {
          flthp = 0.00001
        }
        if flthp > 0.1 {
          flthp = 0.1
        }
      }
      
      var ssample: Float = 0.0
      for _ in 0 ..< 8 { // 8x supersampling
        var sample: Float = 0.0
        phase += 1
        if phase >= period {
          //				phase=0;
          phase %= period
          if p.waveType == .noise {
            for i in 0 ..< 32 {
              noiseBuffer[i] = frnd(2.0) - 1.0
            }
          }
        }
        // base waveform
        let fp = Float(phase) / Float(period)
        switch p.waveType {
        case .square: // square
          if fp < squareDuty {
            sample = 0.5
          } else {
            sample = -0.5
          }
        case .sawtooth: // sawtooth
          sample = 1.0 - fp * 2.0
        case .sine: // sine
          sample = sin(fp * 2.0 * Float.pi)
        case .noise: // noise
          sample = noiseBuffer[phase * 32 / period]
        }
        // lp filter
        let pp = fltp
        fltw *= fltwD
        if fltw < 0.0 {
          fltw = 0.0
        }
        if fltw > 0.1 {
          fltw = 0.1
        }
        if p.lpfFreq != 1.0 {
          fltdp += (sample - fltp) * fltw
          fltdp -= fltdp * fltdmp
        }
        else {
          fltp = sample
          fltdp = 0.0
        }
        fltp += fltdp
        // hp filter
        fltphp += fltp - pp
        fltphp -= fltphp * flthp
        sample = fltphp
        // phaser
        phaserBuffer[ipp & 1023] = sample
        sample += phaserBuffer[(ipp - iphase + 1024) & 1023];
        ipp = (ipp + 1) & 1023
        // final accumulation and envelope application
        ssample += sample * envVol
      }
      ssample = ssample / 8 * p.masterVol
      
      ssample *= 2.0 * p.soundVol
      
      if !exportWave {
        if ssample > 1.0 {
          ssample = 1.0
        }
        if ssample < -1.0 {
          ssample = -1.0
        }
        ptr.pointee = Int16(ssample * 32000.0)
      }
      else {
        // quantize depending on format
        // accumulate/count to accomodate variable sample rate?
        ssample *= 4.0 // arbitrary gain to get reasonable output volume...
        if ssample > 1.0 {
          ssample = 1.0
        }
        if ssample < -1.0 {
          ssample = -1.0
        }
        filesample += ssample
        fileacc += 1
        if wavFreq == 44100 || fileacc == 2 {
          filesample /= Float(fileacc)
          fileacc = 0
          if wavBits == 16 {
            let isample = Int16(filesample * 32000)
            ptr.pointee = isample
          } else {
            //            unsigned char isample = (unsigned char)(filesample * 127 + 128);
            //            fwrite(&isample, 1, 1, file);
          }
          filesample = 0.0
        }
      }
      ptr = ptr.successor()
      framesWritten += 1
    }
    return framesWritten
  }
  
  func play(generator: GeneratorType) {
    Swift.print("play \(generator)")
    switch generator {
    case .pickupCoin:
      p.reset()
      p.baseFreq = 0.4 + frnd(0.5)
      p.envAttack = 0.0
      p.envSustain = frnd(0.1)
      p.envDecay = 0.1 + frnd(0.4)
      p.envPunch = 0.3 + frnd(0.3)
      if brnd() {
        p.arpSpeed = 0.5 + frnd(0.2)
        p.arpMod = 0.2 + frnd(0.4)
      }
    case .laserShoot:
      p.reset()
      p.waveType = WaveType(rawValue: rnd(2))!
      if p.waveType == .sine && brnd() {
        p.waveType = WaveType(rawValue: rnd(1))!
      }
      p.baseFreq = 0.5 + frnd(0.5)
      p.freqLimit = p.baseFreq - 0.2 - frnd(0.6)
      if p.freqLimit < 0.2 {
        p.freqLimit = 0.2
      }
      p.freqRamp = -0.15 - frnd(0.2)
      if rnd(2) == 0 {
        p.baseFreq = 0.3 + frnd(0.6)
        p.freqLimit = frnd(0.1)
        p.freqRamp = -0.35 - frnd(0.3)
      }
      if brnd() {
        p.duty = frnd(0.5)
        p.dutyRamp = frnd(0.2)
      } else {
        p.duty = 0.4 + frnd(0.5)
        p.dutyRamp = -frnd(0.7)
      }
      p.envAttack = 0.0
      p.envSustain = 0.1 + frnd(0.2)
      p.envDecay = frnd(0.4)
      if brnd() {
        p.envPunch = frnd(0.3)
      }
      if rnd(2) == 0 {
        p.phaOffset = frnd(0.2)
        p.phaRamp = -frnd(0.2)
      }
      if brnd() {
        p.hpfFreq = frnd(0.3)
      }
    case .explosion:
      p.reset()
      p.waveType = .noise
      if brnd() {
        p.baseFreq = 0.1 + frnd(0.4)
        p.freqRamp = -0.1 + frnd(0.4)
      } else {
        p.baseFreq = 0.2 + frnd(0.7)
        p.freqRamp = -0.2 - frnd(0.2)
      }
      p.baseFreq *= p.baseFreq
      if rnd(4) == 0 {
        p.freqRamp = 0.0
      }
      if rnd(2) == 0 {
        p.repeatSpeed = 0.3 + frnd(0.5)
      }
      p.envAttack = 0.0
      p.envSustain = 0.1 + frnd(0.3)
      p.envDecay = frnd(0.5)
      if rnd(1) == 0 {
        p.phaOffset = -0.3 + frnd(0.9)
        p.phaRamp = -frnd(0.3)
      }
      p.envPunch = 0.2 + frnd(0.6)
      if brnd() {
        p.vibStrength = frnd(0.7)
        p.vibSpeed = frnd(0.6)
      }
      if rnd(2) == 0 {
        p.arpSpeed = 0.6 + frnd(0.3)
        p.arpMod = 0.8 - frnd(1.6)
      }
    case .powerup:
      p.reset()
      if brnd() {
        p.waveType = .sawtooth
      } else {
        p.duty = frnd(0.6)
      }
      if brnd() {
        p.baseFreq = 0.2 + frnd(0.3)
        p.freqRamp = 0.1 + frnd(0.4)
        p.repeatSpeed = 0.4 + frnd(0.4)
      } else {
        p.baseFreq = 0.2 + frnd(0.3)
        p.freqRamp = 0.05 + frnd(0.2)
        if brnd() {
          p.vibStrength = frnd(0.7)
          p.vibSpeed = frnd(0.6)
        }
      }
      p.envAttack = 0.0
      p.envSustain = frnd(0.4)
      p.envDecay = 0.1 + frnd(0.4)
    case .hitHurt:
      p.reset();
      p.waveType = WaveType(rawValue: rnd(2))!
      if p.waveType == .sine {
        p.waveType = .noise
      }
      if p.waveType == .square {
        p.duty = frnd(0.6)
      }
      p.baseFreq = 0.2 + frnd(0.6)
      p.freqRamp = -0.3 - frnd(0.4)
      p.envAttack = 0.0
      p.envSustain = frnd(0.1)
      p.envDecay = 0.1 + frnd(0.2)
      if brnd() {
        p.hpfFreq=frnd(0.3)
      }
    case .jump:
      p.reset()
      p.waveType = .square
      p.duty = frnd(0.6)
      p.baseFreq = 0.3 + frnd(0.3)
      p.freqRamp = 0.1 + frnd(0.2)
      p.envAttack = 0.0
      p.envSustain = 0.1 + frnd(0.3)
      p.envDecay = 0.1 + frnd(0.2)
      if brnd() {
        p.hpfFreq = frnd(0.3)
      }
      if brnd() {
        p.lpfFreq = 1.0 - frnd(0.6)
      }
    case .blipSelect:
      p.reset()
      p.waveType = WaveType(rawValue: rnd(1))!
      if p.waveType == .square {
        p.duty = frnd(0.6)
      }
      p.baseFreq = 0.2 + frnd(0.4)
      p.envAttack = 0.0
      p.envSustain = 0.1 + frnd(0.1)
      p.envDecay = frnd(0.2)
      p.hpfFreq = 0.1
    }
    
    playSample()
  }
  
  func prepare() {
    let ioUnitDesc = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                               componentSubType: kAudioUnitSubType_HALOutput,
                                               componentManufacturer: kAudioUnitManufacturer_Apple,
                                               componentFlags: 0,
                                               componentFlagsMask: 0)
    
    let ioUnit = try! AUAudioUnit(componentDescription: ioUnitDesc,
                                  options: AudioComponentInstantiationOptions())
    guard let renderFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                           sampleRate: 44100.0,
                                           channels: 1,
                                           interleaved: false) else {
      fatalError()
    }
    try! ioUnit.inputBusses[0].setFormat(renderFormat)
    
    ioUnit.outputProvider = { (actionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
      timestamp: UnsafePointer<AudioTimeStamp>,
      frameCount: AUAudioFrameCount,
      busIndex: Int,
      rawBufferList: UnsafeMutablePointer<AudioBufferList>) -> AUAudioUnitStatus in
      
      let bufferList = UnsafeMutableAudioBufferListPointer(rawBufferList)
      if bufferList.count > 0 {
        let nframes = Int(bufferList[0].mDataByteSize) / MemoryLayout<Int16>.size
        if var ptr = bufferList[0].mData?.bindMemory(to: Int16.self, capacity: nframes) {
          if self.playingSample && !self.muteStream {
            let _ = self.synthSample(pointer: ptr, numberOfFrames: nframes)
          }
          else {
            for _ in 0 ..< nframes {
              ptr.pointee = Int16(0)
              ptr = ptr.successor()
            }
          }
        }
      }
      return noErr
    }
    
    try! ioUnit.allocateRenderResources()
    try! ioUnit.startHardware()
    
    self.ioUnit = ioUnit
  }
  
  deinit {
    if let ioUnit = ioUnit {
      ioUnit.stopHardware()
    }
  }
}

