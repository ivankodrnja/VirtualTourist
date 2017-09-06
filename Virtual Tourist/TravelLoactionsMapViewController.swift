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
    
    var stack: CoreDataStack!
    
    // MARK: Properties
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search
            fetchedResultsController?.delegate = self
            executeSearch()
        }
    }
    
    // MARK: Initializers
    /*
    init(fetchedResultsController fc : NSFetchedResultsController<NSFetchRequestResult>) {
        fetchedResultsController = fc
        super.init()
    }
    */
    // Do not worry about this initializer. I has to be implemented
    // because of the way Swift interfaces with an Objective C
    // protocol called NSArchiving. It's not relevant.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(TravelLoactionsMapViewController.editAction))
        
        // method for getting the map's state before app exited
        restoreMapRegion(false)
        
        // long press gesture recognizer instance
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(TravelLoactionsMapViewController.longTap(_:)))
        mapView.addGestureRecognizer(longPressGR)
        
        // this class is MKMapViewDelegate
        self.mapView.delegate = self
        
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
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
            UIView.animate(withDuration: 0.2, animations: {
            self.mapView.frame.origin.y += self.tapPinsLabel.frame.height
            })
        
        } else {
            self.navigationItem.rightBarButtonItem?.title = "Done"
            UIView.animate(withDuration: 0.2, animations: {
            self.mapView.frame.origin.y -= self.tapPinsLabel.frame.height
            })

        }
        self.editMode = !self.editMode
        

    }
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    
    /*
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: stack.context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
  */
    func createAnnotations(){
        
        var annotations = [Pin]()
        
        if let locations = fetchedResultsController?.fetchedObjects {
            for location in locations {
                annotations.append(location as! Pin)
            }
            
            
        }
        
        self.mapView.addAnnotations(annotations)
    }

 // MARK: - CoreData Fetches
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))")
            }
        }
    }
    
     // MARK: - Long Tap
    
    func longTap(_ gestureRecognizer:UIGestureRecognizer) {
        // handle long tap if edit mode is not active
        if !self.editMode{
            
            // coordinates of a point the user touched on the map
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let newCoord:CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            switch gestureRecognizer.state {
            case .began:
                // create a pin
                var locationDictionary = [String : AnyObject]()
                locationDictionary[Pin.Keys.latitude] = newCoord.latitude as AnyObject
                locationDictionary[Pin.Keys.longitude] = newCoord.longitude as AnyObject
                self.droppedPin = Pin(dictionary: locationDictionary, context: stack.context)
                
                // add the pin to the map
                DispatchQueue.main.async(execute: {
                    self.mapView.addAnnotation(self.droppedPin)
                })
            case .changed:
                droppedPin.willChangeValue(forKey: "coordinate")
                droppedPin.safeCoordinate = newCoord
                droppedPin.didChangeValue(forKey: "coordinate")
                
            case .ended:
                // prefetch images
                FlickrClient.sharedInstance().getPhotos(self.droppedPin){(result, error) in
                    if error == nil {
                        
                        // Parse the array of photos dictionaries
                        DispatchQueue.main.async{
                            _ = result?.map() {(dictionary: [String : AnyObject]) -> Photo in
                                
                                let photo = Photo(dictionary: dictionary, pin: self.droppedPin, context: self.fetchedResultsController!.managedObjectContext)
                                // set the relationship
                                //photo.pin = self.droppedPin
                                
                                FlickrClient.sharedInstance().getPhotoForImageUrl(photo){(success, error) in
                                    
                                    if error == nil {
                                        
                                        DispatchQueue.main.async(execute: {
                                            /*
                                            do {
                                                    try self.stack.saveContext()
                                            } catch {
                                                print("Error: \(String(describing: error.localizedDescription))")
                                            }
                                            */
                                        })
                                        
                                    } else {
                                        // We won't alert the user
                                        print("Error: \(String(describing: error?.localizedDescription))")
                                    }
                                }
                                
                                return photo
                            }
                        }
                    } else {
                        // Error, e.g. the pin has no images or the internet connection is offline
                        print("Error: \(String(describing: error?.localizedDescription))")
                        self.showAlertView(error?.localizedDescription)
                    }
                }
                // save data
                DispatchQueue.main.async{
                    /*
                    do {
                        try self.stack.saveContext()
                    } catch {
                        print("Error: \(String(describing: error.localizedDescription))")
                    }
                    */
                }
            default:
                return
                
            }
            
        }
    }

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
        if(segue.identifier == "showPhotos"){
            let photoAlbumVC:PhotoAlbumViewController = segue.destination as! PhotoAlbumViewController
            photoAlbumVC.selectedPin = self.droppedPin
        }
    
    }

    
    // MARK: - Map delegate methods
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor.red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // annotation (pin) selection is enabled only in edit mode
        if self.editMode {
 
               
            // to delete the pin, first creat an object to delete
            let pinToDelete = view.annotation as! Pin
            print("pinToDelete:\(pinToDelete)")
            
            // remove from context
            fetchedResultsController?.managedObjectContext.delete(pinToDelete)
            DispatchQueue.main.async{
                /*
                do {
                    try self.stack.saveContext()
                } catch {
                    print("Error: \(String(describing: error.localizedDescription))")
                }
                */
            }
            
        } else {
            
            let touchedPin = view.annotation as! Pin
            self.droppedPin = touchedPin
            mapView.deselectAnnotation(touchedPin, animated: false)
            // segue to the photos view
            self.performSegue(withIdentifier: "showPhotos", sender: self)
            
        }
    }
    
    // MARK: - NSFetchedResultsController delegate methods
    
    

    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let pin = anObject as! Pin
        
        switch (type){
        case .insert:
            mapView.addAnnotation(pin)
            
        case .delete:
            mapView.removeAnnotation(pin)
            
        default:
            return
        }
        
    }
    
    // MARK: - Save the zoom level helpers
    
    // A convenient property
    var filePath : String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        return url.appendingPathComponent("mapRegionArchive").path
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
    
    func restoreMapRegion(_ animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [String : AnyObject] {
            
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
    
    func showAlertView(_ errorMessage: String?) {
        
        let alertController = UIAlertController(title: nil, message: errorMessage!, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel) {(action) in
            
            
        }
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true){
            
        }
        
    }
    
}
