//
//  Date+Extension.swift
//  ImageVideoPicker
//
//  Created by Ion Utale on 13/03/2018.
//  Copyright © 2018 ion.utale. All rights reserved.
//

import UIKit

extension Date {
    static func timeFromSeconds(seconds: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let date = Date(timeIntervalSince1970: seconds)
        return dateFormatter.string(from: date)
    }
}
