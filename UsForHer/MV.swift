//
//  MV.swift
//  UsForHer
//
//  Created by Ben Levy on 3/21/21.
//

import SwiftUI
import MapKit
import Firebase

struct MV: UIViewRepresentable {
    var annotations: [MKPointAnnotation]
    var incidents: [IncidentPin]
    var center: CLLocationCoordinate2D
    @State var selectedAnnotation = mapAnnotation(tag: "", time: Timestamp.init())
    @State var locManager = LocationManager()
    
    var didSelect: (mapAnnotation) -> ()  // callback
    
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.region =  MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
      //  mapView.setCenter(locManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.342159, longitude: -122.025620), animated: true)
        return mapView
    }
    func getAnnotCount()->Int{
        return annotations.count
    }
    func updateUIView(_ view: MKMapView, context: Context) {
        if annotations.count != view.annotations.count {
            view.removeAnnotations(view.annotations)
            view.addAnnotations(annotations)
        }
        
    }
    
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MV
        private var counter = 0
        
        init(_ parent: MV) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            let annotationView = NonClusteringMKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
            annotationView.animatesWhenAdded = true
            annotationView.canShowCallout = true
            annotationView.subtitleVisibility = MKFeatureVisibility.hidden
            if(counter < 5){
                if(parent.locManager.locationStatus?.rawValue ?? 0 > 2){
                mapView.setRegion(MKCoordinateRegion(center: parent.locManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude:0), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)), animated: true)
                }
            }
            let btn = UIButton(type: .detailDisclosure) //creating button
            annotationView.rightCalloutAccessoryView = btn  
            switch annotation.title!! {
            case "Verbal Assault/Cat Call":
                annotationView.markerTintColor = UIColor.red
                annotationView.glyphImage = UIImage(named: "VerbalAssult")
            case "Suspicious Behaviour":
                annotationView.markerTintColor = UIColor.blue
                annotationView.glyphImage = UIImage(named: "SuspicousBehavior")
            case "Following/Stalking":
                annotationView.markerTintColor = UIColor.yellow
                annotationView.glyphImage = UIImage(named: "FollowingStalking")
            case "Other":
                annotationView.markerTintColor = UIColor.gray
                annotationView.glyphImage = UIImage(named: "OtherIcon")
            case "My Location":
                annotationView.markerTintColor = .clear
                annotationView.canShowCallout = false
                annotationView.image = UIImage(named: "user location")
                annotationView.titleVisibility = MKFeatureVisibility.hidden
            default:
                annotationView.markerTintColor = UIColor.gray
            }
            
            return annotationView
        }
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let v = view.annotation as? mapAnnotation{
                parent.didSelect(v) // << here !!
            }
        }
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            mapView.setRegion(MKCoordinateRegion(center: view.annotation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)), animated: true)
        }
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            print("test")
            counter += 1
        }
    }
}
