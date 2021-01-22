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
    
    var currentPin:Pin!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var flickrParameterValues:FlickrParameterValues?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //get stored photos
        getPhotosForCurrentPin()
        
        if let flickrValues=currentPin.flickrParameterValues{
            self.flickrParameterValues=flickrValues
        }
        
        if let photos = currentPin.photos, photos.count > 0 {
            label.isHidden=true
        }
        else {
            //if there are no photos stored, fetch from Flickr
            
            isFetching(isFetching: true)
            FlickrClient.getPhotos(lat: currentPin.latitude, long: currentPin.longitude,page:1, completion: handleFlickrResponse(response: error:))
        }
        
        
        // Generate pin for the current pin
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate.latitude=currentPin.latitude
        myPin.coordinate.longitude=currentPin.longitude
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        
        mapView.showAnnotations([myPin], animated: true)
        
        
    }
    ///load stored photos
    fileprivate func getPhotosForCurrentPin(){
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", currentPin)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "\(String(describing: currentPin))-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        
    }
    ///update UI when fetching
    func isFetching(isFetching:Bool){
        if(isFetching){
            label.text="DownLoading"
            
            indicator.startAnimating()
        }else{
            indicator.stopAnimating()
        }
        newCollectionButton.isEnabled = !isFetching
        label.isHidden = !isFetching
        
    }
    
    
    
    func handleFlickrResponse(response: FlickrResponse?, error: Error?) {
        isFetching(isFetching: false)
        guard let response=response else {
            label.text="No Images"
            label.isHidden=false
            print(error?.localizedDescription ?? "error")
            return
        }
        flickrParameterValues=FlickrParameterValues(context:DataController.shared.viewContext)
        flickrParameterValues!.totalPages=Int16(response.photos.pages)
        flickrParameterValues!.photosPerPage=Int16(response.photos.perpage)
        try? DataController.shared.viewContext.save()
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
            let photo=Photo(context:DataController.shared.viewContext)
            photo.pin=self.currentPin
            try? DataController.shared.viewContext.save()
            FlickrClient.getPhotoFromURL(url: url){data,error in
                DispatchQueue.main.async {
                    photo.photo=data
                    try? DataController.shared.viewContext.save()
                }
            }
        }
    }
    
    @IBAction func newCollectionTap(_ sender: Any) {
        var page: Int {
            if let totalPages = flickrParameterValues?.totalPages {
                let page = min(totalPages, 4000/flickrParameterValues!.photosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }
        
        if let photos = fetchedResultsController.fetchedObjects
        {
            for photo in photos
            {
                DataController.shared.viewContext.delete(photo)
                try? DataController.shared.viewContext.save()
            }
            
        }
        isFetching(isFetching: true)
        FlickrClient.getPhotos(lat: currentPin.latitude, long: currentPin.longitude,page: page, completion: handleFlickrResponse(response: error:))
        
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
        
        if let img = photo.photo{
            
            cell.imageView.image=UIImage(data:img)
        }else{
            //set placeholder image
            cell.imageView.image=UIImage(systemName:"photo")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        
        DataController.shared.viewContext.delete(self.fetchedResultsController.object(at: indexPath))
        try? DataController.shared.viewContext.save()
        
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
