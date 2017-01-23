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

let GeneratorSelectedNotification = Notification.Name(rawValue: "GeneratorSelectedNotification")
let MutateSelectedNotification = Notification.Name(rawValue: "MutateSelectedNotification")
let RandomizeSelectedNotification = Notification.Name(rawValue: "RandomizeSelectedNotification")
let ParameterChangedNotification = Notification.Name(rawValue: "ParameterChangedNotification")

class ViewController: NSSplitViewController {
  let sfxrGenerator = SFXRGenerator()
  var parameterViewController: ParameterViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(ViewController.generatorSelected(notification:)),
                                           name: GeneratorSelectedNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(ViewController.mutate(notification:)),
                                           name: MutateSelectedNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(ViewController.randomize(notification:)),
                                           name: RandomizeSelectedNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(ViewController.parameterChanged(notification:)),
                                           name: ParameterChangedNotification,
                                           object: nil)
    sfxrGenerator.prepare()
    for vc in self.childViewControllers {
      if let paramVC = vc as? ParameterViewController {
        paramVC.updateUI(parameters: sfxrGenerator.parameters)
        self.parameterViewController = paramVC
      }
    }
    precondition(self.parameterViewController != nil)
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func generatorSelected(notification: Notification) {
    guard let generator = notification.userInfo?["generator"] as? GeneratorType else {
      return
    }
    self.sfxrGenerator.play(generator: generator)
    updateUI()
  }
  
  func mutate(notification: Notification) {
    self.sfxrGenerator.mutate()
    self.sfxrGenerator.playSample()
    updateUI()
  }
  
  func randomize(notification: Notification) {
    self.sfxrGenerator.random()
    self.sfxrGenerator.playSample()
    updateUI()
  }
  
  func updateUI() {
    self.parameterViewController.updateUI(parameters: self.sfxrGenerator.parameters)
    if let winCtrl = self.view.window?.windowController as? WindowController {
      winCtrl.waveTypeSegmentedControl.selectedSegment = self.sfxrGenerator.parameters.waveType.rawValue
    }
  }
  
  func parameterChanged(notification: Notification) {
    self.parameterViewController.updateParameters(parameters: &self.sfxrGenerator.parameters)
    self.sfxrGenerator.playSample()
  }
  
  func openDocument(_ sender: Any) {
    guard let window = self.view.window else {
      return
    }
    let panel = NSOpenPanel()
    panel.title = "Open"
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    panel.allowedFileTypes = ["sfxr"]
    panel.canSelectHiddenExtension = true
    panel.beginSheetModal(for: window) { (result) in
      if result == NSFileHandlingPanelOKButton {
        if let url = panel.urls.first {
          self.sfxrGenerator.loadSettings(url: url)
          self.parameterViewController.updateUI(parameters: self.sfxrGenerator.parameters)
        }
      }
    }
  }
  
  func saveDocument(_ sender: Any) {
    guard let window = self.view.window else {
      return
    }
    let panel = NSSavePanel()
    panel.title = "Save"
    panel.allowedFileTypes = ["sfxr"]
    panel.canSelectHiddenExtension = true
    panel.beginSheetModal(for: window) { (result) in
      if result == NSFileHandlingPanelOKButton {
        if let url = panel.url {
          self.sfxrGenerator.saveSettings(url: url)
        }
      }
    }
  }
  
  @IBAction func export(_ sender: Any) {
    guard let window = self.view.window else {
      return
    }
    let panel = NSSavePanel()
    panel.title = "Export .WAV"
    panel.allowedFileTypes = ["wav"]
    panel.canSelectHiddenExtension = true
    panel.beginSheetModal(for: window) { (result) in
      if result == NSFileHandlingPanelOKButton {
        if let url = panel.url {
          let data = self.sfxrGenerator.exportWAV()
          try! data.write(to: url)
        }
      }
    }
  }
  
  func play(_ sender: Any) {
    self.sfxrGenerator.playSample()
  }
}

