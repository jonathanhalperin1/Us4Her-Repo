//
//  Banner.swift
//  UsForHer
//
//  

import Foundation
class Banner: ObservableObject {
     var Description: String
    var Version: String

    init(Description: String, Version: String) {
          self.Description = Description
            self.Version = Version
     }
}
