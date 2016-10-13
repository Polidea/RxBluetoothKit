//
//  NSDataUtilities.swift
//  Example
//
//  Created by Kacper Harasim on 19.04.2016.
//  Copyright © 2016 Polidea. All rights reserved.
//

import Foundation

extension Data {

    /// Return hexadecimal string representation of NSData bytes
    var hexadecimalString: String {
        var bytes = [UInt8](repeating: 0, count: count)
        copyBytes(to: &bytes, count: count)

        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
        }
        return NSString(string: hexString) as String
    }
    
    // Return Data represented by this hexadecimal string
    static func fromHexString(string: String) -> Data {
        var data = Data(capacity: string.characters.count / 2)
        
        do {
            let regex = try NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
            regex.enumerateMatches(in: string, options: [], range: NSMakeRange(0, string.characters.count)) { match, flags, stop in
                if let _match = match {
                    let byteString = (string as NSString).substring(with: _match.range)
                    if var num = UInt8(byteString, radix: 16) {
                        data.append(&num, count: 1)
                    }
                }
            }
        } catch {
        
        }
        
        return data
    }
}
