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

import Cocoa

func createHorizontalLine() -> NSBox {
  let line = NSBox()
  line.boxType = .separator
  return line
}

func createSlider(value: Double, bipolar: Bool, target: Any) -> NSSlider {
  if !bipolar {
    let slider = NSSlider(value: value, minValue: 0.0, maxValue: 1.0,
                          target: target, action: #selector(ParameterViewController.didSliderUpdate(_:)))
    slider.isContinuous = false
    slider.numberOfTickMarks = 2
    return slider
  } else {
    let slider = NSSlider(value: value, minValue: -1.0, maxValue: 1.0,
                          target: target, action: #selector(ParameterViewController.didSliderUpdate(_:)))
    slider.isContinuous = false
    slider.numberOfTickMarks = 3
    return slider
  }
}


class ParameterViewController: NSViewController {
  var envelopeAttackTimeSlider: NSSlider!
  var envelopeSustainTimeSlider: NSSlider!
  var envelopeSustainPunchSlider: NSSlider!
  var envelopeDecayTimeSlider: NSSlider!
  
  var startFrequencySlider: NSSlider!
  var minimumFrequencyLimitSlider: NSSlider!
  var frequencySlideSlider: NSSlider!
  var frequencyDeltaSlideSlider: NSSlider!
  
  var vibratoDepthSlider: NSSlider!
  var vibratoSpeedSlider: NSSlider!

  var arpeggioChangeAmountSlider: NSSlider!
  var arpeggioChangeSpeedSlider: NSSlider!

  var squareDutySlider: NSSlider!
  var squareDutySweepSlider: NSSlider!
  
  var repeatSpeedSlider: NSSlider!
  
  var phaserOffsetSlider: NSSlider!
  var phaserSweepSlider: NSSlider!
  
  var lowpassFilterCutoffSlider: NSSlider!
  var lowpassFilterCutoffSweepSlider: NSSlider!
  var lowpassFilterResonanceSlider: NSSlider!
  var highpassFilterCutoffSlider: NSSlider!
  var highpassFilterCutoffSweepSlider: NSSlider!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let horizontalLine1 = createHorizontalLine()
    let horizontalLine2 = createHorizontalLine()
    let horizontalLine3 = createHorizontalLine()
    let horizontalLine4 = createHorizontalLine()
    let horizontalLine5 = createHorizontalLine()
    let horizontalLine6 = createHorizontalLine()
    
    self.envelopeAttackTimeSlider = createSlider(value: 0.0, bipolar: false, target: self)
    self.envelopeSustainTimeSlider = createSlider(value: 0.3, bipolar: false, target: self)
    self.envelopeSustainPunchSlider = createSlider(value: 0.4, bipolar: false, target: self)
    self.envelopeDecayTimeSlider = createSlider(value: 0.0, bipolar: false, target: self)
    
    self.startFrequencySlider = createSlider(value: 0.0, bipolar: false, target: self)
    self.minimumFrequencyLimitSlider = createSlider(value: 0.0, bipolar: false, target: self)
    self.frequencySlideSlider = createSlider(value: 0.0, bipolar: true, target: self)
    self.frequencyDeltaSlideSlider = createSlider(value: 0.0, bipolar: true, target: self)

    self.vibratoDepthSlider = createSlider(value: 0.0, bipolar: false, target: self)
    self.vibratoSpeedSlider = createSlider(value: 0.0, bipolar: false, target: self)
    
    self.arpeggioChangeAmountSlider = createSlider(value: 0.0, bipolar: true, target: self)
    self.arpeggioChangeSpeedSlider = createSlider(value: 0.0, bipolar: false, target: self)
    
    self.squareDutySlider = createSlider(value: 0.0, bipolar: false, target: self)
    self.squareDutySweepSlider = createSlider(value: 0.0, bipolar: true, target: self)

    self.repeatSpeedSlider = createSlider(value: 0.0, bipolar: false, target: self)
    
    self.phaserOffsetSlider = createSlider(value: 0.0, bipolar: true, target: self)
    self.phaserSweepSlider = createSlider(value: 0.0, bipolar: true, target: self)
    
    self.lowpassFilterCutoffSlider = createSlider(value: 0.0, bipolar: false, target: self)
    self.lowpassFilterCutoffSweepSlider = createSlider(value: 0.0, bipolar: true, target: self)
    self.lowpassFilterResonanceSlider = createSlider(value: 0.0, bipolar: false, target: self)
    self.highpassFilterCutoffSlider = createSlider(value: 0.0, bipolar: false, target: self)
    self.highpassFilterCutoffSweepSlider = createSlider(value: 0.0, bipolar: true, target: self)
    
    let gridView = NSGridView(views: [
      [NSTextField(labelWithString: "Attack Time"), envelopeAttackTimeSlider],
      [NSTextField(labelWithString: "Sustain Time"), envelopeSustainTimeSlider],
      [NSTextField(labelWithString: "Sustain Punch"), envelopeSustainPunchSlider],
      [NSTextField(labelWithString: "Decay Time"), envelopeDecayTimeSlider],
      [horizontalLine1],
      
      [NSTextField(labelWithString: "Start Frequency"), startFrequencySlider],
      [NSTextField(labelWithString: "Min Frequency"), minimumFrequencyLimitSlider],
      [NSTextField(labelWithString: "Slide"), frequencySlideSlider],
      [NSTextField(labelWithString: "Delta Slide"), frequencyDeltaSlideSlider],
      
      [NSTextField(labelWithString: "Vibrato Depth"), vibratoDepthSlider],
      [NSTextField(labelWithString: "Vibrato Speed"), vibratoSpeedSlider],
      [horizontalLine2],
      
      [NSTextField(labelWithString: "Change Amount"), arpeggioChangeAmountSlider],
      [NSTextField(labelWithString: "Change Speed"), arpeggioChangeSpeedSlider],
      [horizontalLine3],
      
      [NSTextField(labelWithString: "Square Duty"), squareDutySlider],
      [NSTextField(labelWithString: "Duty Sweep"), squareDutySweepSlider],
      [horizontalLine4],
      
      [NSTextField(labelWithString: "Repeat Speed"), repeatSpeedSlider],
      [horizontalLine5],
      
      [NSTextField(labelWithString: "Phaser Offset"), phaserOffsetSlider],
      [NSTextField(labelWithString: "Phaser Sweep"), phaserSweepSlider],
      [horizontalLine6],
      
      [NSTextField(labelWithString: "Low-Pass Filter Cutoff"), lowpassFilterCutoffSlider],
      [NSTextField(labelWithString: "Low-Pass Filter Cutoff Sweep"), lowpassFilterCutoffSweepSlider],
      [NSTextField(labelWithString: "Low-Pass Filter Resonance"), lowpassFilterResonanceSlider],
      [NSTextField(labelWithString: "High-Pass Filter Cutoff"), highpassFilterCutoffSlider],
      [NSTextField(labelWithString: "High-Pass Filter Cutoff Sweep"), highpassFilterCutoffSweepSlider],
      
      ])
    
    let cell1 = gridView.cell(for: horizontalLine1)!
    cell1.row!.mergeCells(in: NSRange(location: 0, length: 2))
    let cell2 = gridView.cell(for: horizontalLine2)!
    cell2.row!.mergeCells(in: NSRange(location: 0, length: 2))
    let cell3 = gridView.cell(for: horizontalLine3)!
    cell3.row!.mergeCells(in: NSRange(location: 0, length: 2))
    let cell4 = gridView.cell(for: horizontalLine4)!
    cell4.row!.mergeCells(in: NSRange(location: 0, length: 2))
    let cell5 = gridView.cell(for: horizontalLine5)!
    cell5.row!.mergeCells(in: NSRange(location: 0, length: 2))
    let cell6 = gridView.cell(for: horizontalLine6)!
    cell6.row!.mergeCells(in: NSRange(location: 0, length: 2))
    
    gridView.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(gridView)
    
    let views = ["gridView" : gridView]
    let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[gridView]-|", options: [], metrics: [:], views: views)
    let verticallConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-60-[gridView]", options: [], metrics: [:], views: views)
    NSLayoutConstraint.activate(horizontalConstraints)
    NSLayoutConstraint.activate(verticallConstraints)
  }
  
  func updateUI(parameters params: Parameters) {
    self.envelopeAttackTimeSlider.floatValue = params.envAttack
    self.envelopeSustainTimeSlider.floatValue = params.envSustain
    self.envelopeSustainPunchSlider.floatValue = params.envPunch
    self.envelopeDecayTimeSlider.floatValue = params.envDecay
    
    self.startFrequencySlider.floatValue = params.baseFreq
    self.minimumFrequencyLimitSlider.floatValue = params.freqLimit
    self.frequencySlideSlider.floatValue = params.freqRamp
    self.frequencyDeltaSlideSlider.floatValue = params.freqDramp
    
    self.vibratoDepthSlider.floatValue = params.vibStrength
    self.vibratoSpeedSlider.floatValue = params.vibSpeed
    
    self.arpeggioChangeAmountSlider.floatValue = params.arpMod
    self.arpeggioChangeSpeedSlider.floatValue = params.arpSpeed
    
    self.squareDutySlider.floatValue = params.duty
    self.squareDutySweepSlider.floatValue = params.dutyRamp
    
    self.repeatSpeedSlider.floatValue = params.repeatSpeed
    
    self.phaserOffsetSlider.floatValue = params.phaOffset
    self.phaserSweepSlider.floatValue = params.phaRamp
    
    self.lowpassFilterCutoffSlider.floatValue = params.lpfFreq
    self.lowpassFilterCutoffSweepSlider.floatValue = params.lpfRamp
    self.lowpassFilterResonanceSlider.floatValue = params.lpfResonance
    self.highpassFilterCutoffSlider.floatValue = params.hpfFreq
    self.highpassFilterCutoffSweepSlider.floatValue = params.hpfRamp
  }
  
  func updateParameters(parameters params: inout Parameters) {
    params.envAttack = self.envelopeAttackTimeSlider.floatValue
    params.envSustain = self.envelopeSustainTimeSlider.floatValue
    params.envPunch = self.envelopeSustainPunchSlider.floatValue
    params.envDecay = self.envelopeDecayTimeSlider.floatValue
    
    params.baseFreq = self.startFrequencySlider.floatValue
    params.freqLimit = self.minimumFrequencyLimitSlider.floatValue
    params.freqRamp = self.frequencySlideSlider.floatValue
    params.freqDramp = self.frequencyDeltaSlideSlider.floatValue
    
    params.vibStrength = self.vibratoDepthSlider.floatValue
    params.vibSpeed = self.vibratoSpeedSlider.floatValue
    
    params.arpMod = self.arpeggioChangeAmountSlider.floatValue
    params.arpSpeed = self.arpeggioChangeSpeedSlider.floatValue
    
    params.duty = self.squareDutySlider.floatValue
    params.dutyRamp = self.squareDutySweepSlider.floatValue
    
    params.repeatSpeed = self.repeatSpeedSlider.floatValue
    
    params.phaOffset = self.phaserOffsetSlider.floatValue
    params.phaRamp = self.phaserSweepSlider.floatValue
    
    params.lpfFreq = self.lowpassFilterCutoffSlider.floatValue
    params.lpfRamp = self.lowpassFilterCutoffSweepSlider.floatValue
    params.lpfResonance = self.lowpassFilterResonanceSlider.floatValue
    params.hpfFreq = self.highpassFilterCutoffSlider.floatValue
    params.hpfRamp = self.highpassFilterCutoffSweepSlider.floatValue
  }
  
  @objc func didSliderUpdate(_ sender: Any) {
    NotificationCenter.default.post(name: ParameterChangedNotification, object: self)
  }
  
}
