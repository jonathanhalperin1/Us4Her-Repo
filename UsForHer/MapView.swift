import SwiftUI
import MapKit
import FirebaseDatabase
import Firebase


struct MapView: View {
    @State var region = MKCoordinateRegion()

    let locManager = LocationManager()
    
     var incidents : [IncidentPin]
    
    
  @State  var buttonDisplayedState: Bool = false
    @State var displayedInfo: IncidentPin =  IncidentPin(latitude: 0, longitude: 0, type: "", ExtraInfo: "", time: Timestamp(seconds: 0, nanoseconds: 0))
    private let zeroIncident = IncidentPin(latitude: 0, longitude: 0, type: "", ExtraInfo: "", time: Timestamp(seconds: 0, nanoseconds: 0)) //cleared var
    private let zero = CLLocationCoordinate2D(latitude: 37.342159, longitude: -122.025620)
    
    let displayUserSelectionAnnatation : Bool = false
     let center: CLLocationCoordinate2D = CLLocationCoordinate2D()
     let centerCoordinate = CLLocationCoordinate2D  ()
    
//    let timeManager = TimeManager()

    public mutating func addIncident(_ input: IncidentPin){
        // print(input)
        incidents.append(input)
        
        print("||||||")
        for element in incidents {
            print(element)
        }
    }

    mutating func setRegion(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: locManager.lastLocation?.coordinate ?? zero,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    }
    
    public func saveInfo(_ input: IncidentPin){
        displayedInfo = input
        
        //debug
        print("info saved")
        print("button display state: ")
        print(buttonDisplayedState)
        
        
    }
    
    public mutating func setCenter(){
        setRegion(locManager.lastLocation?.coordinate ?? zero)
        print("Center set")
    }
    
//    public func clearVars(){
//        displayedInfo = zeroIncident
//        buttonDisplayedState = false
//    }
    public func getRegion() -> Binding<MKCoordinateRegion>{
        return $region
    }
    
    public func getColor(_ input: IncidentPin)-> Color{
        let incidentOptions = ["Verbal Assualt/Cat Call", "Suspicous Behaviour", "Following/Stalking", "Other"]
        
        if(input.type.elementsEqual( incidentOptions[0])){
            return Color.red
        }
        if(input.type.elementsEqual( incidentOptions[1])){
            return Color.yellow
        }
        if(input.type.elementsEqual( incidentOptions[2])){
            return Color.orange
        }
        return Color.gray
    }
    func getZoom(_ regionDelta: MKCoordinateSpan) -> CGFloat{
        let latDif = regionDelta.latitudeDelta
        let longDif = regionDelta.latitudeDelta
         var calculate : Double
        
        if(latDif > longDif){
            calculate = longDif
        }else{
            calculate = latDif
        }
        
        return (111 / CGFloat(calculate))/20
    }
 
    mutating func remove(_ element: IncidentPin){
        let index = find(value: element, in: incidents)!
        incidents.remove(at: index)
    }
    private func find(value searchValue: IncidentPin, in array: [IncidentPin]) -> Int?
    {
        for (index, value) in array.enumerated()
        {
            if value.id == searchValue.id {
                return index
            }
        }

        return nil
    }
    func hoursFromIncident(_ input: IncidentPin) -> String{
        let incidentTimestamp : Double = Double(input.time.seconds)
        let curTimestamp : Double = Double(Timestamp.init().seconds)
        
        let difTimestamp = curTimestamp - incidentTimestamp
        
        let difHours = difTimestamp / 3600
        
        let roundedDif = (difHours).rounded()
        let convertedToInt : Int64 = Int64(roundedDif)
        if(convertedToInt == 0){
            return "Within the Last Hour"
        }
        return "\(convertedToInt) hours ago"

    }
    
    let screenSize = UIScreen.main.bounds.size
    
    let incidentRegion = Circle()

    
    var body: some View {
        Map(
            coordinateRegion: getRegion(),
            interactionModes: MapInteractionModes.all,
            showsUserLocation: true,
            annotationItems: incidents
        ){ incident in
            MapAnnotation(coordinate: incident.coordinate, anchorPoint: CGPoint(x: 0.5, y: 0.5)) {
//                Circle()
//                    .fill(getColor(incident))
//                    .opacity(0.4)
//                    .frame(width: getZoom(region.span) , height: getZoom(region.span))
                Button(){
                    buttonDisplayedState = true
                    saveInfo(incident)
                } label: {
                   Circle()
                        .fill(getColor(incident))
                       .opacity(0.4)
               //       .frame(width: 155 , height: 155)  //ADD MULTIPLIER TO check both????
                        .frame(width: getZoom(region.span) , height: getZoom(region.span))  //ADD MULTIPLIER TO check both????
                    }
                }

            }
        
        
//        .onAppear{
//            setCenter()
//        }
        
//        
//        Button(){
//            setCenter()
//        } label:{
//            Image("Recenter")
//                .resizable()
//                .frame(width: 55, height: 55)
//
//        }
//        .position(x: 38, y: 800)
        
        
        if(buttonDisplayedState){
            
            ZStack{
                Rectangle() //creating rectangle for incident report
                    .fill(getColor(displayedInfo))
                    .frame(width: 364, height: 264)
                    .cornerRadius(20.0)
                
                Rectangle() //creating rectangle for incident report
                    .fill(Color.white)
                    .frame(width: 352, height: 252)
                    .cornerRadius(14.0)
                
                HStack{
                    Spacer()
                    Text(displayedInfo.type)
                        .fontWeight(.bold)
                    Spacer()
                }
                //title
                .font(.title)
                .foregroundColor(Color.black)
                .position(x: (screenSize.width/2), y: 330)
                
                HStack{
                    Text(displayedInfo.ExtraInfo)
                        .frame(width: 340, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                }
                Text("\(hoursFromIncident(displayedInfo))")
                    .fontWeight(.thin)
                    .position(x: (screenSize.width/2), y: 530)

                
                
                Button() { //close button
                    buttonDisplayedState  = false
                 //   clearVars()
                } label: {
                    ZStack{
                        Image("exit")
                            .resizable()
                            .frame(width: 50, height: 52)

                    }
                }
                .position(x: 350, y:325)
                
            }
            
            
        }
        
        
    }
}

