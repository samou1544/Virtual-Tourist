//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Asma  on 1/20/21.
//

import UIKit
import Foundation
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout, MKMapViewDelegate{
    
    let userDefaultsKey="lastRegion"
    var photoslist = [UIImage]()
       
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectedCoordinateLat:Double!
    var selectedCoordinateLong:Double!

    override func viewDidLoad() {
        super.viewDidLoad()
        FlickrClient.getPhotos(lat: selectedCoordinateLat, long: selectedCoordinateLong, completion: handleFlickrResponse(response: error:))
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate.latitude=selectedCoordinateLat
        myPin.coordinate.longitude=selectedCoordinateLong
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        if let array = readSavedMapPosition() {
            print("Loading saved region")
            let mkcr = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: array[0], longitude: array[1]), span: MKCoordinateSpan(latitudeDelta: array[2], longitudeDelta: array[3]))
            mapView.setRegion(mkcr, animated: true)
        }
        //mapView.showAnnotations([myPin], animated: true)

    }
    func handleFlickrResponse(response: FlickrResponse?, error: Error?) {
        guard let response=response else {
            print(error?.localizedDescription ?? "error")
            return
        }
        
        downloadPhotos(list:response.photos.photo)
        
    }
    func downloadPhotos(list:[Photo]){
        for item in list{
            guard let url=URL(string: item.url_n) else {
                return
            }
            FlickrClient.getPhotoFromURL(url: url, completion: handleImageFileResponse(data: error:))
        }
    }
    func handleImageFileResponse(data: Data?, error: Error?) {
        DispatchQueue.main.async {
            let downloadedImage = UIImage(data: data!)
            self.photoslist.append(downloadedImage!)
            print("new image added")
            self.collectionView.reloadData()
        }
    }
    
    func readSavedMapPosition() -> [Double]? {
        let array = UserDefaults.standard.value(forKey: userDefaultsKey) as? [Double]
        return array
    }
    @IBAction func newCollectionTap(_ sender: Any) {
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoslist.count
   }
   
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
       let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! PhotoCell
        let photo = photoslist[(indexPath as NSIndexPath).row]
       
       // Set the name and image
        cell.imageView.image=photo
       
       return cell
   }
   
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
       
       /*let detailController = self.storyboard!.instantiateViewController(withIdentifier: "memeDetailVC") as! MemeDetailViewController
       detailController.meme = self.memes[(indexPath as NSIndexPath).row].memedImage
       self.navigationController!.pushViewController(detailController, animated: true)*/
       
   }
    
    //Adjusting Item size
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let noOfCellsInRow = 3
        let size = Int(collectionView.bounds.width / CGFloat(noOfCellsInRow))
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {     return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
        
    }
}
