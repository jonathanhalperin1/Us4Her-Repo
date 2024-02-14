//
//  TimeManager.swift
//  UsForHer
//
//  
//

import Foundation
import Firebase
struct  TimeManager {
    
    func getCurrentTimeString()-> String{
        let now = Date()
        
        let formatter = DateFormatter()
        
        
        let datetime = formatter.string(from: now)
        return datetime
    }
    
    func parseStringToDate(_ isoDate: String)-> Date{
        let formatter = ISO8601DateFormatter()
        
        let def = Date()
        
        return formatter.date(from:isoDate) ?? def
    }
    
    func parseDataToString(_ s: Date)-> String{
        let formatter = DateFormatter()
        
        return formatter.string(from: s)
    }
    func parseFIRTimestamptoString(_ t : Timestamp)-> Date{
        
        return t.dateValue()
        
    }
    
    
    func printTime(){
        let now = Date()
        print("/time;")
        print(now)
        print("/")
        
    }
}
