//
//  MapLocationSelect.swift
//  UsForHer
//
//  Created by Ben Levy on 3/14/21.
//
import MapKit

import SwiftUI

import Firebase

struct MapLocationSelect: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @ObservedObject var locManager = LocationManager()
    
    
    @State var incidents = [IncidentPin]()
    
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
    
    func getCenterLat() -> Double{
        return self.centerCoordinate.latitude
    }
    func getCenterLong() -> Double{
        return self.centerCoordinate.longitude
    }
    func makeUIView(context: Context) -> MKMapView {
        let mapLocationSelect = MKMapView()
        mapLocationSelect.region =  MKCoordinateRegion(center: locManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.342159, longitude: -122.025620), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
        mapLocationSelect.delegate = context.coordinator
        return mapLocationSelect
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("Updating")
        
        Firestore.firestore().collection("incidentDB")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
            
        
            let t = documents.map { $0["type"]  ?? "INFO NOT FOUND" }
            let extraInfo = documents.map { $0["extra info"] ?? "INFO NOT FOUND" }
                let lat = documents.map { $0["lat"] ?? 0.0}
                let long = documents.map { $0["long"] ?? 0.0 }
                print(t)
                print(extraInfo)
                print(lat)
                print(long)
            }
        
        uiView.showsUserLocation = true
    }
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapLocationSelect
        
        init(_ parent: MapLocationSelect) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.centerCoordinate = mapView.centerCoordinate
        }
        
    }
    
}

extension MKPointAnnotation{
    static var example: MKPointAnnotation{
        let annatation = MKPointAnnotation()
        annatation.title = "London"
        annatation.subtitle = "Home to the 2012 Summer Olympics"
        annatation.coordinate = (CLLocationCoordinate2D(latitude: 51.5, longitude: -0.13))
        return annatation
    }
}
struct MapLocationSelect_Previews: PreviewProvider {
    static var previews: some View {
        MapLocationSelect(centerCoordinate: .constant(MKPointAnnotation.example.coordinate))
    }
}

