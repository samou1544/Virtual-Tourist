//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Asma  on 1/20/21.
//

import UIKit
import Foundation
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout, MKMapViewDelegate{
    
    var dataController:DataController!
    var currentPin:Pin!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //get photos from coreData
        getPhotosForCurrentPin()
        
        if let photos = currentPin.photos, photos.count > 0 {
            label.isHidden=true
        }
        else {
            newCollectionButton.isEnabled=false
            label.text="DownLoading"
            indicator.startAnimating()
            FlickrClient.getPhotos(lat: currentPin.latitude, long: currentPin.longitude, completion: handleFlickrResponse(response: error:))
        }
        
        
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate.latitude=currentPin.latitude
        myPin.coordinate.longitude=currentPin.longitude
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        
        mapView.showAnnotations([myPin], animated: true)
        
        
    }
    
    fileprivate func getPhotosForCurrentPin(){
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", currentPin)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        
    }
    func handleFlickrResponse(response: FlickrResponse?, error: Error?) {
        newCollectionButton.isEnabled=true
        indicator.stopAnimating()
        label.isHidden=true
        guard let response=response else {
            label.text="No Images"
            label.isHidden=false
            print(error?.localizedDescription ?? "error")
            return
        }
        downloadPhotos(list:response.photos.photo)
        
    }
    func downloadPhotos(list:[FlickrPhoto]){
        if(list.isEmpty){
            label.text="No Images"
            label.isHidden=false
        }
        for item in list{
            guard let url=URL(string: item.url_n) else {
                return
            }
            let photo=Photo(context:self.dataController.viewContext)
            photo.pin=self.currentPin
            try? self.dataController.viewContext.save()
            FlickrClient.getPhotoFromURL(url: url){data,error in
                DispatchQueue.main.async {
                    photo.photo=data
                    try? self.dataController.viewContext.save()
                }
            }
        }
    }
    func handleImageFileResponse(photo:Photo, data: Data?, error: Error?) {
        DispatchQueue.main.async {
            photo.photo=data
            try? self.dataController.viewContext.save()
            
        }
    }
    @IBAction func newCollectionTap(_ sender: Any) {
        
        if let photos = fetchedResultsController.fetchedObjects
        {
            for photo in photos
            {
                self.dataController.viewContext.delete(photo)
                try? self.dataController.viewContext.save()
            }
            
        }
        
        FlickrClient.getPhotos(lat: currentPin.latitude, long: currentPin.longitude, completion: handleFlickrResponse(response: error:))
        
    }
    
    //MARK: CollectionView delegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! PhotoCell
        let photo = fetchedResultsController.object(at: indexPath)
        //cell.imageView.image=UIImage(data:photo.photo!)
        
        if let img = photo.photo{
        
        // Set the name and image
            cell.imageView.image=UIImage(data:img)
        }else{
            cell.imageView.image=UIImage(systemName:"pencil")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        
        dataController.viewContext.delete(self.fetchedResultsController.object(at: indexPath))
        try? self.dataController.viewContext.save()
        
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
