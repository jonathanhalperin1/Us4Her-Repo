//
//  mapAnnotation.swift
//  UsForHer
//
//  Created by Ben Levy on 3/20/21.
//

import Foundation
import MapKit
import Firebase
class mapAnnotation: MKPointAnnotation {
     var tag: String
    var time: Timestamp

    init(tag: String, time: Timestamp) {
          self.tag = tag
        self.time = time
     }
}
