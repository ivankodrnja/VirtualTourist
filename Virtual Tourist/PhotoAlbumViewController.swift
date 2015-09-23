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

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    var selectedPin : Pin!
    var page : Int = 1
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected"
    var selectedIndexes = [NSIndexPath]()
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        setMapRegion(true)
        
        self.mapView.addAnnotation(selectedPin)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
        
        // this class is NSFetchedResultsControllerDelegate
        fetchedResultsController.delegate = self
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        if let error = error {
            println("Error: \(error.localizedDescription)")
            self.showAlertView("There was a problem with this pin. Please go back to the map and drop a new one.")
        }

        // check if there are available photos associted with the pin, and if no act accordingly
        if fetchedResultsController.fetchedObjects?.count == 0 {
            self.noImagesLabel.hidden = false
            bottomButton.enabled = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.leftBarButtonItem?.title = "OK"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor((self.collectionView.frame.size.width-20)/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)
        
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
    
    // MARK: - Configure Cell
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
        
        if let index = find(selectedIndexes, indexPath) {
            cell.imageView.alpha = 0.5
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    // MARK: - Collection View
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // reset pevious images in the xell
        cell.imageView.image = nil
        
        // makeing sure the activity indicator is animating
        cell.activityView.startAnimating()
        
        // if there is an image, update the cell appropriately
        if photo.image != nil {
            
            cell.activityView.stopAnimating()
            cell.imageView.alpha = 0.0
            cell.imageView.image = photo.image
            
            UIView.animateWithDuration(0.2,
                animations: { cell.imageView.alpha = 1.0 })
        }
        // modify the cell
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        //Disallow selection if the cell is waiting for its image to appear.
        if cell.activityView.isAnimating() {
            
            return false
        }
        
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell

        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        updateBottomButton()
    }
    
    // MARK: - NSFetchedResultsControler delegate methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break

        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        //Check to make sure UI elements are correctly displayed.
        if controller.fetchedObjects?.count > 0 {
            
            noImagesLabel.hidden = true
            bottomButton.enabled = true
        }
        //Make the relevant updates to the collectionView once Core Data has finished its changes.
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    
    @IBAction func bottomButtonClicked() {
        
        if selectedIndexes.count == 0 {
            updateBottomButton()
            newPhotoCollection()
        } else {
            deleteSelectedPhotos()
            
            updateBottomButton()
            // save on the main thread (part of getting Core Data thread safe)
            dispatch_async(dispatch_get_main_queue()){
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
    }
    
    // MARK: - Helpers
    
    func newPhotoCollection(){
        bottomButton.enabled = false
        
        page += 1
        
        // delete existing photos
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        // save on the main thread (part of getting Core Data thread safe)
        dispatch_async(dispatch_get_main_queue()){
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        FlickrClient.sharedInstance().getPhotos(selectedPin, pageNumber: page){(result, error) in
            
            if error == nil {
                
                // Parse the array of photos dictionaries
                dispatch_async(dispatch_get_main_queue()){
                    var photos = result?.map() {(dictionary: [String : AnyObject]) -> Photo in
                        
                        let photo = Photo(dictionary: dictionary, pin: self.selectedPin, context: self.sharedContext)
                        // set the relationship
                        //photo.pin = self.selectedPin
                        FlickrClient.sharedInstance().getPhotoForImageUrl(photo){(success, error) in
                            
                            if error == nil {
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    CoreDataStackManager.sharedInstance().saveContext()
                                    self.bottomButton.enabled = true
                                })
                                
                            } else {
                                // We won't alert the user
                                println("Error: \(error?.localizedDescription)")
                                self.bottomButton.enabled = true
                            }
                        }
                        
                        return photo
                    }
                }
            } else {
                // Error, e.g. the pin has no images or the internet connection is offline
                println("Error: \(error?.localizedDescription)")
                self.showAlertView(error?.localizedDescription)
            }
        }
        // save data
        dispatch_async(dispatch_get_main_queue()){
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        // remove the deleted image indexes
        selectedIndexes = []
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    
    func showAlertView(errorMessage: String?) {
        
        let alertController = UIAlertController(title: nil, message: errorMessage!, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Dismiss", style: .Cancel) {(action) in
            
            
        }
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true){
            
        }
        
    }
    
}
