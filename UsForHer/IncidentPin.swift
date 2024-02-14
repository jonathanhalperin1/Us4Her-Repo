//
//  IncidentPin.swift
//  UsForHer
//
// 
//

import Foundation
import SwiftUI
import CoreLocation
import Firebase

struct IncidentPin: Identifiable {


//properties
    var id = String()
    var latitude: Double
    var longitude: Double
    var type: String
    var ExtraInfo: String
    var time: Timestamp
    var coordinate: CLLocationCoordinate2D {
      return .init(latitude: latitude, longitude: longitude)
    }

}
