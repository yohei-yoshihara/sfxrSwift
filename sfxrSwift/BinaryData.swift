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

class BinaryData {
  var data = Data()
  
  init() {}
  init(data: Data) {
    self.data = data
  }
  func append(_ s: String) {
    data.append((s.data(using: .ascii))!)
  }
  func append(_ v: UInt8) {
    data.append(v)
  }
  func append(_ v: UInt16) {
    data.append(UInt8(v & 0xff))
    data.append(UInt8((v >> 8) & 0xff))
  }
  func append(_ v: UInt32) {
    data.append(UInt8(v & 0xff))
    data.append(UInt8((v >> 8) & 0xff))
    data.append(UInt8((v >> 16) & 0xff))
    data.append(UInt8((v >> 24) & 0xff))
  }
  func append(_ v: Float) {
    append(v.bitPattern)
  }
  func append(_ v: Bool) {
    append(UInt8(v ? -1 : 0))
  }
  // UInt8
  func uint8(at index: Int) -> UInt8 {
    return data[index]
  }
  func setUInt8(_ value: UInt8, at index: Int) {
    data[index] = value
  }
  // UInt16
  func uint16(at index: Int) -> UInt16 {
    precondition(index + 1 < data.count)
    return (UInt16(data[index + 1]) << 8) | UInt16(data[index])
  }
  func setUInt16(_ value: UInt16, at index: Int) {
    precondition(index + 1 < data.count)
    data[index] = UInt8(value & 0xff)
    data[index + 1] = UInt8((value >> 8) & 0xff)
  }
  // UInt32
  func uint32(at index: Int) -> UInt32 {
    precondition(index + 3 < data.count)
    return (UInt32(data[index + 3]) << 24) |
      (UInt32(data[index + 2]) << 16) |
      (UInt32(data[index + 1]) <<  8) |
      UInt32(data[index])
  }
  func setUInt32(_ value: UInt32, at index: Int) {
    precondition(index + 3 < data.count)
    data[index] = UInt8(value & 0xff)
    data[index + 1] = UInt8((value >> 8) & 0xff)
    data[index + 2] = UInt8((value >> 16) & 0xff)
    data[index + 3] = UInt8((value >> 24) & 0xff)
  }
  // Float
  func float(at index: Int) -> Float {
    let ui32: UInt32 = self.uint32(at: index)
    return Float(bitPattern: ui32)
  }
  func setFloat(_ value: Float, at index: Int) {
    self.setUInt32(value.bitPattern, at: index)
  }
  // Bool
  func bool(at index: Int) -> Bool {
    let ui8: UInt8 = self.uint8(at: index)
    return ui8 != 0
  }
  func setBool(_ value: Bool, at index: Int) {
    self.setUInt8(UInt8(value ? 255 : 0), at: index)
  }
}

