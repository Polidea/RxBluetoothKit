//
//  NSDataUtilities.swift
//  Example
//
//  Created by Kacper Harasim on 19.04.2016.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation

extension NSData {

    /// Return hexadecimal string representation of NSData bytes
    var hexadecimalString: String {
        var bytes = [UInt8](count: length, repeatedValue: 0)
        getBytes(&bytes, length: length)

        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
        }
        return NSString(string: hexString) as String
    }

    public class func createFromHexString(string: String) -> NSData {
        let data = NSMutableData()

        var temp = ""
        for char in string.characters {
            temp += String(char)
            if string.characters.count == 2 {
                let scanner = NSScanner(string: temp)
                var value: CUnsignedInt = 0
                scanner.scanHexInt(&value)
                data.appendBytes(&value, length: 1)
                temp = ""
            }
        }
        return data as NSData
    }

}
