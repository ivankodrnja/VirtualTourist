//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 17/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var selectedPin : Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        setMapRegion(true)
        
        self.mapView.addAnnotation(selectedPin)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
        
        fetchedResultsController.performFetch(nil)
        // this class is NSFetchedResultsControllerDelegate
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.leftBarButtonItem?.title = "OK"
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
    
    
    // MARK: - Map
    
    func setMapRegion(animated: Bool) {

        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        
        let savedRegion = MKCoordinateRegion(center: selectedPin.coordinate, span: span)
        
        mapView.setRegion(savedRegion, animated: animated)
    }
}
