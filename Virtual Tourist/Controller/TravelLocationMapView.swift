//
//  TravelLocationMapView.swift
//  Virtual Tourist
//
//  Created by Asma  on 1/19/21.
//

import UIKit
import MapKit

class TravelLocationMapView: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let segueIdentifier="showPhotoAlbumView"
    let userDefaultsKey="lastRegion"
    var selectedLat:Double? = nil
    var selectedLong:Double? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Generate long-press UIGestureRecognizer.
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        // Read saved coordinate region from NSUserDefaults
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
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        // Do not generate pins many times during long press.
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        // Get the coordinates of the point you pressed long.
        let location = sender.location(in: mapView)
        
        // Convert location to CLLocationCoordinate2D.
        let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate = myCoordinate
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        
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
        selectedLat=view.annotation?.coordinate.latitude
        selectedLong=view.annotation?.coordinate.longitude
        performSegue(withIdentifier: segueIdentifier, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            let photoAlbumVC = segue.destination as! PhotoAlbumViewController
            photoAlbumVC.selectedCoordinateLat=selectedLat
            photoAlbumVC.selectedCoordinateLong=selectedLong
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
    
}

