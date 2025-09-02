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

let ThemeChangedNotification = Notification.Name(rawValue: "ThemeChangedNotification")

class WindowController: NSWindowController {
  @IBOutlet weak var waveTypeSegmentedControl: NSSegmentedControl!
  
  override func windowDidLoad() {
    super.windowDidLoad()
    
    self.window!.titleVisibility = .hidden
    
    // Set default window size and constraints
    if let window = self.window {
      window.setFrameAutosaveName("MainWindow")
      if !window.frameAutosaveName.isEmpty {
        // If there is no saved frame yet, apply defaults
        if !UserDefaults.standard.bool(forKey: "MainWindowHasLaunched") {
          window.setContentSize(NSSize(width: 600, height: 700))
          window.center()
          UserDefaults.standard.set(true, forKey: "MainWindowHasLaunched")
        }
      } else {
        window.setContentSize(NSSize(width: 600, height: 700))
        window.center()
      }
      window.minSize = NSSize(width: 600, height: 700)
      window.maxSize = NSSize(width: 600, height: 700)
      window.styleMask.remove(.resizable)
    }
    
    if UserDefaults.standard.bool(forKey: UseDarkModeKey) {
      self.window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
    }
    else {
      self.window?.appearance = nil
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(WindowController.themeChanged(notification:)), name: ThemeChangedNotification, object: nil)

    // Play sound when wave type segmented control changes
    self.waveTypeSegmentedControl.target = self
    self.waveTypeSegmentedControl.action = #selector(waveTypeChanged(_:))
  }
  
  @objc func themeChanged(notification: Notification) {
    if let useDarkTheme = notification.userInfo?[UseDarkModeKey] as? NSNumber {
      if useDarkTheme.boolValue {
        self.window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        UserDefaults.standard.set(useDarkTheme.boolValue, forKey: UseDarkModeKey)
      }
      else {
        self.window?.appearance = nil
        UserDefaults.standard.set(useDarkTheme.boolValue, forKey: UseDarkModeKey)
      }
    }
  }
  
  @objc func waveTypeChanged(_ sender: NSSegmentedControl) {
    guard let vc = self.window?.contentViewController as? ViewController else {
      return
    }
    let idx = sender.selectedSegment
    guard idx >= 0 && idx <= maxWaveTypeRawValue else {
      return
    }
    if let wt = WaveType(rawValue: idx) {
      vc.sfxrGenerator.stop()
      let params = vc.sfxrGenerator.parameters
      params.waveType = wt
      vc.sfxrGenerator.parameters = params
      vc.sfxrGenerator.playSample()
      vc.updateUI()
    }
  }

}
