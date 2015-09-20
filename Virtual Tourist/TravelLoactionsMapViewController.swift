//
//  TravelLoactionsMapViewController.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 12/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLoactionsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapPinsLabel: UILabel!
    
    // will serve for edit mode detection
    var editMode : Bool = false
    // will serve to detect the exct pin that was selected when transitioning to PhotoAlbum
    var droppedPin : Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editAction")
        
        // method for getting the map's state before app exited
        restoreMapRegion(false)
        
        // long press gesture recognizer instance
        var longPressGR = UILongPressGestureRecognizer(target: self, action: "longTap:")
        mapView.addGestureRecognizer(longPressGR)
        
        // this class is MKMapViewDelegate
        self.mapView.delegate = self
        
        fetchedResultsController.performFetch(nil)
        // this class is NSFetchedResultsControllerDelegate
        fetchedResultsController.delegate = self
        
        // add annotations from Core Data
        self.createAnnotations()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func editAction() {
   
        if(self.editMode){
            
            self.navigationItem.rightBarButtonItem?.title = "Edit"
            UIView.animateWithDuration(0.2, animations: {
            self.mapView.frame.origin.y += self.tapPinsLabel.frame.height
            })
        
        } else {
            self.navigationItem.rightBarButtonItem?.title = "Done"
            UIView.animateWithDuration(0.2, animations: {
            self.mapView.frame.origin.y -= self.tapPinsLabel.frame.height
            })

        }
        self.editMode = !self.editMode
        

    }
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    func createAnnotations(){
        
        var annotations = [Pin]()
        
        if let locations = fetchedResultsController.fetchedObjects {
            for location in locations {
                annotations.append(location as! Pin)
            }
            
            
        }
        
        self.mapView.addAnnotations(annotations)
    }

     // MARK: - Long Tap
    
    func longTap(gestureRecognizer:UIGestureRecognizer) {
        // handle long tap if edit mode is not active
        if !self.editMode{
            
            // coordinates of a point the user touched on the map
            var touchPoint = gestureRecognizer.locationInView(self.mapView)
            var newCoord:CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            
            switch gestureRecognizer.state {
            case .Began:
                // create a pin
                var locationDictionary = [String : AnyObject]()
                locationDictionary[Pin.Keys.latitude] = newCoord.latitude
                locationDictionary[Pin.Keys.longitude] = newCoord.longitude
                self.droppedPin = Pin(dictionary: locationDictionary, context: sharedContext)
                
                // add the pin to the map
                dispatch_async(dispatch_get_main_queue(), {
                    self.mapView.addAnnotation(self.droppedPin)
                })
            case .Changed:
                droppedPin.willChangeValueForKey("coordinate")
                droppedPin.coordinate = newCoord
                droppedPin.didChangeValueForKey("coordinate")
                
            case .Ended:
                // prefetch images
                FlickrClient.sharedInstance().getPhotos(self.droppedPin){(result, error) in
                    if error == nil {
                        
                        // Parse the array of photos dictionaries
                        var photos = result?.map() {(dictionary: [String : AnyObject]) -> Photo in
                            
                            let photo = Photo(dictionary: dictionary, pin: self.droppedPin, context: self.sharedContext)
                            // set the relationship
                            //photo.pin = self.droppedPin
                            
                            FlickrClient.sharedInstance().getPhotoForImageUrl(photo){(success, error) in
                                
                                if error == nil {
                                    
                                    dispatch_async(dispatch_get_main_queue(), {
                                        CoreDataStackManager.sharedInstance().saveContext()
                                    })
                                    
                                } else {
                                    // TODO: handle error
                                    println("error")
                                }
                            }
                            
                            return photo
                        }
                        
                    } else {
                        // TODO: handle error
                        println("error")
                    }
                }
                // save data
                CoreDataStackManager.sharedInstance().saveContext()
                
            default:
                return
                
            }
            
        }
    }

    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
        if(segue.identifier == "showPhotos"){
            let photoAlbumVC:PhotoAlbumViewController = segue.destinationViewController as! PhotoAlbumViewController
            photoAlbumVC.selectedPin = self.droppedPin
        }
    
    }

    
    // MARK: - Map delegate methods
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinColor = .Red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        // annotation (pin) selection is enabled only in edit mode
        if self.editMode {
            if let pinAnnotation = view  {
               
                // to delete the pin, first creat an object to delete
                let pinToDelete = pinAnnotation.annotation as! Pin
                println("pinToDelete:\(pinToDelete)")
                
                // remove from context
                sharedContext.deleteObject(pinToDelete)
                CoreDataStackManager.sharedInstance().saveContext()

            }
        } else {
            
            let touchedPin = view.annotation as! Pin
            self.droppedPin = touchedPin
            mapView.deselectAnnotation(touchedPin, animated: false)
            // segue to the photos view
            self.performSegueWithIdentifier("showPhotos", sender: self)
            
        }
    }
    
    // MARK: - NSFetchedResultsController delegate methods
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        let pin = anObject as! Pin
        
        switch (type){
        case .Insert:
            mapView.addAnnotation(pin)
            
        case .Delete:
            mapView.removeAnnotation(pin)
            
        default:
            return
        }
        
    }
    
    // MARK: - Save the zoom level helpers
    
    // A convenient property
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    // MARK: - Helpers
    
    func showAlertView(errorMessage: String?) {
        
        let alertController = UIAlertController(title: nil, message: errorMessage!, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Dismiss", style: .Cancel) {(action) in
            
            
        }
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true){
            
        }
        
    }
    
}