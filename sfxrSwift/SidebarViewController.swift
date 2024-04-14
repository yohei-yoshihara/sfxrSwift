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

class Header: Equatable {
  var label: String
  var items = [Item]()
  init(label: String, items: [Item]) {
    self.label = label
    self.items = items
  }
  public static func ==(lhs: Header, rhs: Header) -> Bool {
    return lhs.label == rhs.label
  }
}

class Item {
  var label: String
  var tag: Int
  init(label: String, tag: Int) {
    self.label = label
    self.tag = tag
  }
  public static func ==(lhs: Item, rhs: Item) -> Bool {
    return lhs.label == rhs.label
  }
}

class SidebarViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
  @IBOutlet weak var outlineView: NSOutlineView!
  
  static let MutateTag = -1
  static let RandomizeTag = -2
  
  var headers = [
    Header(label: "Generator", items: [
      Item(label: "Pickup/Coin", tag: GeneratorType.pickupCoin.rawValue),
      Item(label: "Laser/Shoot", tag: GeneratorType.laserShoot.rawValue),
      Item(label: "Explosion", tag: GeneratorType.explosion.rawValue),
      Item(label: "Powerup", tag: GeneratorType.powerup.rawValue),
      Item(label: "Hit/Hurt", tag: GeneratorType.hitHurt.rawValue),
      Item(label: "Jump", tag: GeneratorType.jump.rawValue),
      Item(label: "Blip/Select", tag: GeneratorType.blipSelect.rawValue),
      ]),
    Header(label: "Quick", items: [
      Item(label: "Mutate", tag: MutateTag),
      Item(label: "Randomize", tag: RandomizeTag)
      ])
  ]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.outlineView.delegate = self
    self.outlineView.dataSource = self
    self.outlineView.expandItem(nil, expandChildren: true)
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      return self.headers.count
    }
    else if let header = item as? Header {
      return header.items.count
    }
    return 0
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    return item is Header
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if item == nil {
      return self.headers[index]
    }
    else if let header = item as? Header {
      return header.items[index]
    }
    fatalError()
  }
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    if let header = item as? Header {
      let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("HeaderCell"), owner: nil) as! NSTableCellView
      cell.textField?.stringValue = header.label
      return cell
    }
    if let item = item as? Item {
      let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: nil) as! NSTableCellView
      cell.textField?.stringValue = item.label
      return cell
    }
    fatalError()
  }
  
  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
    return item is Header
  }
  
  func outlineViewSelectionDidChange(_ notification: Notification) {
    guard let selectedItem = self.outlineView.item(atRow: self.outlineView.selectedRow) as? Item else {
      return
    }
    
    if 0 <= selectedItem.tag && selectedItem.tag <= maxGeneratorTypeRawValue {
      Swift.print("select row \(self.outlineView.selectedRow)")
      self.outlineView.deselectAll(self)
      let generator = GeneratorType(rawValue: selectedItem.tag)!
      NotificationCenter.default.post(name: GeneratorSelectedNotification, object: self, userInfo: ["generator" : generator])
    }
    else if selectedItem.tag == SidebarViewController.MutateTag {
      self.outlineView.deselectAll(self)
      NotificationCenter.default.post(name: MutateSelectedNotification, object: self, userInfo: [:])
    }
    else if selectedItem.tag == SidebarViewController.RandomizeTag {
      self.outlineView.deselectAll(self)
      NotificationCenter.default.post(name: RandomizeSelectedNotification, object: self, userInfo: [:])
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
    return item is Item
  }
}
