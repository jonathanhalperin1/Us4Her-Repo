//
//  ContentView.swift
//  UsForHer
//
// 
//

import SwiftUI
import MapKit
import Firebase
import UIKit
import UserNotifications
import CoreLocation

struct ContentView: View {
    //General Variables
    @ObservedObject var locManager = LocationManager()
    @State var addButtonState: Bool = false
    private var incidentOptions = ["Verbal Assault/Cat Call", "Suspicious Behaviour", "Following/Stalking", "Other"]
    @State private var selection = 1
    @State var otherUserInput: String = ""
    @State var userDescriptionInput: String = "Description..."
    @State var submitState: Bool = false
    @State var mapSelector: Bool = false
    @State private var locSelection = 1
    private var locOptions = ["Use my Location", "Use other Location"]
    @State private var displayCircle: Bool = false
    let logoColor = Color(red: 0.9137, green: 0.6313, blue: 0.9058)
    
    @State var incidents = [IncidentPin]()
    //Map Stuff Variables
    @State var selctedPlace = MKPointAnnotation()
    @State var showingPlaceDetails = false
    //    @State var mapView : MapView = MapView()
    @State private var centerCoordinate = CLLocationCoordinate2D()
    @State private var zero = CLLocationCoordinate2D(latitude: 37.342159, longitude: -122.025620)
    
    @State private var verifyState = false
    //Time Management Variables
    //  @State var timeManager = TimeManager()
    let timer = Timer.publish(every: 30, on: .current, in: .common).autoconnect()
    @State var newDate = Date()
    
    //Notification Variable
    let locationNotificationScheduler = LocationNotificationScheduler()
    
    //Anti-Spam Variable
    @State var submitTime = Timestamp.init().seconds
    @State var mostRecentIncidentPin = IncidentPin.init(latitude: 0, longitude: 0, type: "", ExtraInfo: "", time: Timestamp.init(seconds: 0, nanoseconds: 0))
    @State var showingLocationTooFarAlert = false
    @State var timeError = false
    //Getting Device Size()
    let screenSize = UIScreen.main.bounds.size
    //Showing Info
    @State var showInfo = false
    @State var savedInfoPin = mapAnnotation(tag: "", time: Timestamp.init())
        
    //banner
    @State var bannerState = false
    @State var bannerDescription = ""
    //AntiSpam
    func checkIfEnoughTimePassed(_ submitTime: Timestamp, _ timePassed: Int64 ) -> Bool{
        let currentTime = Timestamp.init()
        let dif = currentTime.seconds - submitTime.seconds
        
        if(dif > timePassed){
            return true
        }
        return false
    }
    
    //Notifications
    func scheduleLocationNotification(_ sender: Any) {
        for element in incidents{
            let titleText = "WARNING: \(element.type) near your location"
            let notInfo = LocationNotificationInfo.init(notificationId: element.id, locationId: element.id, radius: 400, latitude: element.latitude, longitude: element.longitude, title: titleText, body: element.ExtraInfo)
            locationNotificationScheduler.requestNotification(with: notInfo)
        }
    }
    
    //General Update Method SUPER IMPORTANT (runs every second)
    func update() {
        let ref = Firestore.firestore().collection("incident_DB")
        ref
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let id = documents.map{ $0 ["id"] ?? "ID NOT FOUND"}
                let t = documents.map { $0["type"]  ?? "INFO NOT FOUND" }
                let extraInfo = documents.map { $0["extra info"] ?? "INFO NOT FOUND" }
                let lat = documents.map { $0["lat"] ?? 0.0}
                let long = documents.map { $0["long"] ?? 0.0 }
                let time = documents.map{ $0["time"] ?? Timestamp(seconds: 0, nanoseconds: 0)}
                if(incidents.count < lat.count){
                    for i in 0..<lat.count{
                        print("ARRAYS DONT MATCH....UPDATING")
                        incidents.append(IncidentPin(id : id[i] as! String, latitude: lat[i] as! Double, longitude: long[i] as! Double, type: t[i] as! String, ExtraInfo: extraInfo[i] as! String, time: time[i] as! Timestamp))
                    }
                }else{
                    print("ARRAY MATCHES DB")
                }
                
                print("Running Update")
                var removeList = [String]()
                
                for element in incidents {
                    if(checkIncidentTime(element, 43200)){
                        remove(element)
                        let targetID: String = element.id
                        removeList.append(targetID)
                        if(contains(id, element.id)){
                            ref.document(element.id).delete()
                            locationNotificationScheduler.deleteNotif(element.id)
                            print(" REMOVED ")
                        }
                    }
                }
                
            }
        if(!(locationNotificationScheduler.getNotifList() == incidents.count)){
            scheduleLocationNotification(self) //compare db to
        }
        locationNotificationScheduler.removeNotificationAfterShow() //delete already shown
    
        
    }
    func remove(_ element: IncidentPin){
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
    
    //Helper
    func contains(_ idArr: [Any],_ target: String)-> Bool{
        for elemennt in idArr{
            if(elemennt as! String == target){
                return true
            }
        }
        return false
        
    }
    //Helper
    func checkIncidentTime(_ n: IncidentPin, _ timeBeforeDeletion: Int) -> Bool{
        let current = Timestamp.init()
        let currentSecCount = current.seconds
        let dif = currentSecCount - n.time.seconds
        if(dif > timeBeforeDeletion){
            print("Removing /\(n)")
            return true
        }
        print("Theres this much time left :/\(dif)")
        print("on /\(n)")
        return false
    }
    func getRegion() -> MKCoordinateRegion{
        return MKCoordinateRegion(
            center: locManager.lastLocation?.coordinate ?? zero,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    }
    
    func convertToAnnot()-> [mapAnnotation]{
        var out = [mapAnnotation]()
        for element in incidents{
            let loc = mapAnnotation(tag: element.id, time: element.time)
            loc.coordinate = element.coordinate
            loc.title = element.type
            loc.subtitle = element.ExtraInfo
            out.append(loc)
        }
        return out
    }
    func getTitleY()-> CGFloat{
        if(screenSize.height > 880 ){
            return 110;
        }else if(screenSize.height > 800){
            return 150
        }
        return 200;
    }
    func getPosX()-> CGFloat{
        let width = screenSize.width/2
        if(screenSize.height > 900 ){
            return width + 163;
        }else if(screenSize.height > 800){
            return width + 160;
        }
        return width + 155;
    }
    func checkLocation(_ inputLoc : CLLocationCoordinate2D, disqualifyDis : Double){
        let currentLoc = locManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let dis = distance(lat1: currentLoc.latitude, lon1: currentLoc.longitude, lat2: inputLoc.latitude, lon2: inputLoc.longitude, unit: "K")
        print(dis)
        if(dis > disqualifyDis){
            showingLocationTooFarAlert = true
        }
        else {showingLocationTooFarAlert = false}
    }
    func deg2rad(deg:Double) -> Double {
        return deg * Double.pi / 180
    }
    func rad2deg(rad:Double) -> Double {
        return rad * 180.0 / Double.pi
    }
    func distance(lat1:Double, lon1:Double, lat2:Double, lon2:Double, unit:String) -> Double {
        let theta = lon1 - lon2
        var dist = sin(deg2rad(deg: lat1)) * sin(deg2rad(deg: lat2)) + cos(deg2rad(deg: lat1)) * cos(deg2rad(deg: lat2)) * cos(deg2rad(deg: theta))
        dist = acos(dist)
        dist = rad2deg(rad: dist)
        dist = dist * 60 * 1.1515
        if (unit == "K") {
            dist = dist * 1.609344
        }
        else if (unit == "N") {
            dist = dist * 0.8684
        }
        return dist
    }
    func containsBadWord(_ input: String) {
        //Sorry for bad words
        let badWords = ["anus","ash0le","ash0les","asholes", "bastard","bastards","bastardz","basterds","basterdz","biatch","bitch","bitches","Blow Job","boffing","butthole","buttwipe","c0ck","c0cks","c0k","Carpet Muncher","cawk","cawks","Clit","cnts","cock","cockhead","cock-head","cocks","CockSucker","cock-sucker","crap","cum","cunt","cunts","cuntz","dick","dild0","dild0s","dildo","dildos","","dilld0s","dominatricks","dominatrics","dominatrix","dyke","enema","f u c k","f u c k e r","fag","fag1t","faget","fagg1t","faggit","faggot","fagit","fags","fagz","faig","faigs","fart","flipping the bird","fuck","fucker","fuckin","fucking","fucks","Fudge Packer","fuk","Fukah","Fuken","fuker","Fukin","Fukk","Fukkah","Fukken","Fukker","Fukkin","g00k","gayboy","gaygirl","gays","gayz","God-damned","h00r","h0ar","h0re","hells","hoar","hoor","hoore","jackoff","jap","japs","jerk-off","jisim","jiss","jizm","jizz","knob","knobs","knobz","kunts","kuntz","Lesbian","Lezzian","Lipshits","Lipshitz","masochist","massterbait","masstrbait","masstrbate","masterbate","masterbates","Motha Fucker","Motha Fuker","Motha Fukkah","Motha Fukker","Mother Fucker","Mother Fukah","Mother Fuker","Mother Fukkah","Mother Fukker","mother-fucker","Mutha Fucker","Mutha Fukah","Mutha Fuker","Mutha Fukkah","Mutha","Fukker","n1gr","nastt","nigger","nigur","niiger","niigr","orafis","orgasim","orgasm","orgasum","oriface","orifice","packi","packie","packy","paki","pakie","paky","pecker","peeenus","peeenusss","peenus","peinus","pen1s","penas","penis","penis-breath","penus","penuus","Phuc","Phuck","Phuk","Phuker","Phukker","polac","polack","polak","Poonani","pr1c","pr1ck","pr1k","pusse","pussee","pussy","puuke","puuker","queer","queers","queerz","qweers","qweerz","qweir","recktum","rectum","retard","sadist","scank","schlon","screwing","semen","sexy","Sh!t","sh1ter","sh1ts","sh1tter","sh1tz","shits","shitter","Shitty","shitz","Shyte","Shytty","Shyty","skanck","skank","skankee","skankey","skanks","Skanky","sluts","Slutty","slutz","son-of-a-bitch","tit","turd","va1jina","vag1navagiina","vagina","vaj1na","vajina","vullva","vulva","w0p","wh00r","wh0re","whore","xrated","xxx","b!+ch","clit","arschloch","fuck","shit","b!tch","b17ch","b1tch","bastard","bi+ch","boiolas","buceta","c0ck","cawk","chink","cipa","clits","cock","cum","cunt","dildo","dirsa","ejakulate","fatass","fcuk","fuk","hoer","hore","jism","kawk","l3itch","l3i+ch","lesbian","masturbate","masterbat*","masterbat3","motherfucker","s.o.b.","mofo","nazi","nigga","nigger","nutsack","phuck","pimpis","pusse","pussy","scrotum","sh!t","shemale","shi+","sh!+","smut","teets","titsboobs","b00bs","teez","testical","testicle","titt","w00se","jackoff","wank","whoar","*dyke","*fuck*","*shit*","@$$","amcik","andskota","arse*","assrammer","ayir","bi7ch","bitch*","bollock*","butt-pirate","cabron","cazzo","chraa","chuj","Cock*","cunt*","d4mn","daygo","dego","dick*","dike*","dupa","dziwka","ejackulate","Ekrem*","Ekto","enculer","faen","fag*","fanculo","fanny","feces","feg","Felcher","ficken","fitt*","Flikker","foreskin","Fotze","Fu(*","fuk*","futkretzn","gay","gook","gguiena","h0r","h4x0r","hell","helvete","hoer*","honkey","Huevon","hui","injun","jizz","kanker*","kike","klootzak","kraut","knulle","kuk","kuksuger","Kurac","kurwa","kusi*","kyrpa*","lesbo","mamhoon","masturbat*","merd*","mibun","monkleigh","mouliewop","muie","mulkku","muschi","nazis","nepesaurio","nigger*","orospu","paska*","perse","picka","pierdol*","pillu*","pimmel","piss*","pizda","poontsee","poop","porn","p0rn","pr0n","preteen","pula","pule","puta","puto","qahbeh","queef*","rautenberg","schaffer","scheiss*","schlampe","schmuck","screw","sh!t*","sharmuta","sharmute","shipal","shiz","skribz","skurwysyn","sphencter","spic","spierdalaj","splooge","suka","b00b*","testicle*","titt*","twat","vittu","wank*","wetback*","wichser","wop*","yed","zabourah"]
        for word in badWords {
            if input.lowercased().contains(word) {
                print("bad word found")
                showingLocationTooFarAlert = true
            }
        }
    }
    func enableMapSelecter(){
        addButtonState = false
        mapSelector = true
        
        UIApplication.shared.endEditing() // Call to dismiss keyboard
    }
    func close(){
        addButtonState = false
    }
    func checkBanner(){
       Firestore.firestore().collection("banner")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let bd = documents.map{ $0 ["Description"] ?? "DESCRIPION NOT FOUND"}
                let ba = documents.map { $0["Version"]  ?? "STATE NOT FOUND" }
            
                let versionString = ba[0] as! String
                bannerDescription = bd[0] as! String
                
                let currentVersion =  Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            
                if(!(versionString == currentVersion)){
                    bannerState = true
                }
                
                if(versionString == "0"){ //ignore version
                    bannerState = false
                }
    }
    }
    var body: some View{
        Text("")
            .onReceive(timer){ input in
                update()
            }
            .position(x: 1000, y: 1000)
        
        let horizCenter = screenSize.width/2
        let mls: MapLocationSelect = MapLocationSelect(centerCoordinate: $centerCoordinate)
       
        let posTitleY = getTitleY()
        let xPos = getPosX()
        var currentLoc = CLLocationCoordinate2D(latitude: 37, longitude: -122)
    
            
        ZStack{
            if(locManager.locationStatus?.rawValue ?? 0 > 2){
              let  currentLoc = locManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.342159, longitude: -122.025620)
            MV(annotations: convertToAnnot(), incidents: incidents, center: currentLoc){annotation in
                savedInfoPin = annotation
                showInfo = true
            }
            .frame(height: 1000) //change size
            }else {
                MV(annotations: convertToAnnot(), incidents: incidents, center: currentLoc){annotation in
                    savedInfoPin = annotation
                    showInfo = true
            }
                .frame(height: 1000) //change size
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Image("tlogo")
                        .resizable()
                        .padding(.top, 20.0)
                        .frame(width:160, height: 85)
                    
                    
                    Spacer()
                }
                .position(x:90, y:  posTitleY)
                
                
                Spacer()
                Spacer()
                Button {
                    addButtonState = true;
                } label: {
                    Image("ReportButton")
                        .resizable()
                        .frame(width: 100, height: 90)
                }
                .position(x: (screenSize.width) - 60,y: (screenSize.height/2) - 80 )
                
            }
            
            if(addButtonState){
                ZStack{
                    Rectangle() //creating rectangle for incident report
                        .fill(Color.black)
                        .frame(width: 352, height: 432)
                        .cornerRadius(4)



                    Rectangle() //creating rectangle for incident report
                        .fill(Color.white)
                        .frame(width: 350, height: 430)
                        .cornerRadius(3)

                    Rectangle() //creating rectangle for incident report
                        .fill(Color.gray)
                        .frame(width: 330, height: 1)
                        .position(x:horizCenter, y:495)

                    HStack{
                        Spacer()
                        Text("Report an Incident")
                            .fontWeight(.bold)
                        Spacer()
                    }
                    //title
                    .font(.title)
                    .foregroundColor(Color.black)
                    .position(x: horizCenter, y: 310)

                    HStack{ //picking an incident
                        Picker("Test", selection: $selection) {
                            ForEach(0..<incidentOptions.count) {
                                Text(self.incidentOptions[$0])
                                    .foregroundColor(Color.black)

                            }

                        }
                        .position(x: 150, y: 410)
                        .frame(width: 300)
                    }

                    Rectangle()
                        .frame(width: 315, height: 165, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .position(x:horizCenter,y:590)



                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 313, height: 163, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .position(x:horizCenter,y:590)

                    TextEditor( text: $userDescriptionInput)
                        .font(.title3)
                        .frame(width: 305, height: 160, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .position(x:horizCenter,y:590)
                        .onTapGesture {
                            if(userDescriptionInput == "Description..."){
                                userDescriptionInput = ""
                            }
                        }

                    //next button
                    Button(){
                        //close the view
                        print("GOT TO ALERT\(verifyState)")
                       verifyState = true
                    } label:{
                        ZStack{
                            Text("Next")
                        }
                    }
                    .alert(isPresented: $verifyState){
                        Alert(
                            title: Text("WARNING"),
                            message: Text("Once you submit an incident it cannot be edited and will be displayed for 12 hours. Any fake or inappropriate incidents will lead to a permanant ban from Us4Her."),
                            primaryButton: .destructive(
                                Text("Cancel"),
                                action: close
                            ),
                            secondaryButton: .default(
                                Text("Continue..."),
                                action: enableMapSelecter
                            )
                        )
                    }
                    .position(x: xPos - 25, y: 692)

                    Button() { //close button
                        addButtonState = false
                        //  update()
                    } label: {
                        ZStack{


                            Image("exit")
                                .resizable()
                                .frame(width:25, height:25)
                        }
                    }
                    .position(x: xPos, y:305)

                }

            }
            if(mapSelector){
                ZStack{

                    if(locSelection == 1){
                        mls
                        Image("MapMarker")
                            .resizable()
                            .frame(width: 90.0, height: 90.0)
                    }
                    if(locSelection == 0){
                        mls
                    }

                    Rectangle() //creating rectangle for incident report
                        .fill(Color.black)
                        .cornerRadius(4)
                        .frame(width: 352, height: 142)
                        .position(x: horizCenter, y: 300)

                    Rectangle() //creating rectangle for incident report
                        .fill(Color.white)
                        .cornerRadius(3)
                        .frame(width: 350, height: 140)
                        .position(x: horizCenter, y: 300)

                    HStack{
                        Spacer()
                        Text("Where?")
                            .fontWeight(.bold)
                        Spacer()
                    }

                    .font(.title)
                    .foregroundColor(Color.black)
                    .position(x: horizCenter, y: 250)


                    HStack{
                        Picker("loc", selection: $locSelection) {
                            ForEach(0..<locOptions.count) {
                                Text(self.locOptions[$0])
                                    .foregroundColor(Color.black)

                            }

                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .position(x: 150, y: 290 )
                        .frame(width: 300)
                    }
                    Button(){
                        mapSelector = false
                        addButtonState = true
                    }label: {
                        Text("Back")
                    }
                    .position(x: 64, y: 352)

                    //Submit Button
                    if(!checkIfEnoughTimePassed(mostRecentIncidentPin.time, 3600)){
                        Button(){
                           timeError = true
                        } label:{
                            ZStack{
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 72.0, height: 37.0)
                                    .cornerRadius(12)
                                Rectangle()
                                    .fill(/*@START_MENU_TOKEN@*/Color.blue/*@END_MENU_TOKEN@*/)
                                    .frame(width: 70.0, height: 35.0)
                                    .cornerRadius(11)
                                Text("Submit")
                                    .font(.headline)
                                    .foregroundColor(Color.white)
                            }
                        }
                        .position(x: horizCenter, y: 340)
                        .alert(isPresented: $timeError){
                            Alert(title: Text("Oops! Something Went Wrong..."), message: Text("You Can Only Submit Once an Hour"), dismissButton: .default(Text("Okay")))
                        }

                    }else{
                        Button(){
                            var pos: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)

                            if(locSelection == 0){
                                pos = CLLocationCoordinate2D(latitude: locManager.lastLocation?.coordinate.latitude ?? 0.0, longitude: locManager.lastLocation?.coordinate.longitude ?? 0.0)
                            }
                            if(locSelection == 1){
                                pos = CLLocationCoordinate2D(latitude: mls.getCenterLat(), longitude: mls.getCenterLong())
                            }
                            checkLocation(pos, disqualifyDis: 50)
                            containsBadWord(userDescriptionInput)
                            if(pos.latitude == 0 && pos.longitude == 0){
                                print("no location found")
                                showingLocationTooFarAlert = true
                            }
                            if(!showingLocationTooFarAlert){
                                print("adding incident at")
                                print(Timestamp.init())
                                let curID = UUID().uuidString
                                if(userDescriptionInput == "Description..."){
                                    userDescriptionInput = ""
                                }
                                let incidentDictionary: [String: Any] = [
                                    "id" : curID,
                                    "type" : incidentOptions[selection],
                                    "extra info":userDescriptionInput,
                                    "lat": pos.latitude,
                                    "long": pos.longitude,
                                    "time": Timestamp.init()
                                ]

                                let docRef = Firestore.firestore().document("incident_DB/\(curID)")
                                print("setting data")

                                docRef.setData(incidentDictionary){ (error) in
                                    if let error = error{
                                        print("error = \(error)")
                                    }else{
                                        print("data uploaded successfully")
                                    }
                                }

                                mostRecentIncidentPin = IncidentPin.init(latitude: pos.latitude, longitude: pos.longitude, type: incidentOptions[selection], ExtraInfo: userDescriptionInput, time: Timestamp.init()) //save most recent incident to check for spam

                                userDescriptionInput = ""
                                mapSelector = false
                                update()
                            }

                        } label:{
                            ZStack{
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 72.0, height: 37.0)
                                    .cornerRadius(12)
                                Rectangle()
                                    .fill(/*@START_MENU_TOKEN@*/Color.blue/*@END_MENU_TOKEN@*/)
                                    .frame(width: 70.0, height: 35.0)
                                    .cornerRadius(11)
                                Text("Submit")
                                    .font(.headline)
                                    .foregroundColor(Color.white)
                            }
                        }
                        .position(x: horizCenter, y: 340)
                        .alert(isPresented: $showingLocationTooFarAlert){
                            Alert(title: Text("Oops! Something Went Wrong..."), message: Text("Please Make Sure the Description is Appropriate, Your Incident is Within 50km of Your Location, and Location Services are Enabled"), dismissButton: .default(Text("Try Again")))
                        }
                    }

                }

            }
            if(showInfo){
                annotationInfo(displayedInfo: savedInfoPin)
                Button() { //close button
                    print("button tapped")
                    showInfo = false
                    //   clearVars()
                } label: {
                    ZStack{
                        Image("exit")
                            .resizable()
                            .frame(width: 25, height: 25)
                        
                    }
                }
                .position(x: screenSize.width/2 + 155, y: 395)
                
            }
        }
        .onAppear(){
            locationNotificationScheduler.clearAll()
            incidents.removeAll()
            update()
            checkBanner()
        }
       
//        .alert(isPresented:$bannerState) {
//            Alert(title: Text("WARNING"),
//                  message: Text(bannerDescription),
//                  dismissButton: .default(Text("Update"), action: { DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                      exit(0)
//                     }
//                }}))
//    }
    }
    
}

extension ContentView { //if loc isn't enable redirect user to go to settings
    func goToDeviceSettings() {
        guard let url = URL.init(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
}



extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        
    }
    
    
}


