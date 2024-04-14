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
    
    if UserDefaults.standard.bool(forKey: UseDarkModeKey) {
      self.window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
    }
    else {
      self.window?.appearance = nil
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(WindowController.themeChanged(notification:)), name: ThemeChangedNotification, object: nil)
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
  
}
