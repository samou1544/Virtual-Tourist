//
//  TravelLocationMapView.swift
//  Virtual Tourist
//
//  Created by Asma  on 1/19/21.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapView: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let segueIdentifier="showPhotoAlbumView"
    let userDefaultsKey="lastRegion"
    
    var selectedPin:Pin?
    var pins:[Pin]=[]
    
    
    ///getting stored pins
    fileprivate func fetchPins() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let result=try? DataController.shared.viewContext.fetch(fetchRequest){
            pins=result
            showPins()
        }
    }
    
    ///displaying pins on the map
    func showPins(){
        var annotations = [MKPointAnnotation]()
        for pin in pins {
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.removeAnnotations(mapView.annotations)
        fetchPins()
        // Generate long-press UIGestureRecognizer.
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        
        // Read saved coordinate region from UserDefaults
        if let array = self.readSavedMapPosition() {
            print("Loading saved region")
            let mkcr = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: array[0], longitude: array[1]), span: MKCoordinateSpan(latitudeDelta: array[2], longitudeDelta: array[3]))
            self.mapView.setRegion(mkcr, animated: true)
        }
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated);
        
        saveMapPosition(region: mapView.region)
        super.viewWillDisappear(animated)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // A method called when long press is detected.
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer){
        
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        let location=sender.location(in: mapView)
        // Convert location to CLLocationCoordinate2D.
        let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate = myCoordinate
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        // Saving the dropped pin
        selectedPin = Pin(context: DataController.shared.viewContext)
        selectedPin!.latitude=myPin.coordinate.latitude
        selectedPin!.longitude=myPin.coordinate.longitude
        try? DataController.shared.viewContext.save()
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        selectedPin=getPinReference(location: view.annotation!.coordinate)
        performSegue(withIdentifier: segueIdentifier, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            let photoAlbumVC = segue.destination as! PhotoAlbumViewController
            photoAlbumVC.currentPin=selectedPin
        }
    }
    
    func saveMapPosition(region: MKCoordinateRegion) {
        let array = [region.center.latitude, region.center.longitude, region.span.latitudeDelta, region.span.longitudeDelta]
        UserDefaults.standard.set(array, forKey: userDefaultsKey)
    }
    
    func readSavedMapPosition() -> [Double]? {
        let array = UserDefaults.standard.value(forKey: userDefaultsKey) as? [Double]
        return array
    }
    
    ///get a Pin reference from coredata of the selected pin
    func getPinReference(location: CLLocationCoordinate2D) -> Pin?
    {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", NSNumber.init(value: location.latitude),NSNumber.init(value: location.longitude))
        if let result = try? DataController.shared.viewContext.fetch(fetchRequest)
        
        {
            return result.first!
        } else {
            return nil
        }
    }
    
}

