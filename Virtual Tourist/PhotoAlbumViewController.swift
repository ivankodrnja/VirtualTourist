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
        
        fetchedResultsController.performFetch(nil)
        // this class is NSFetchedResultsControllerDelegate
        fetchedResultsController.delegate = self
        
        updateBottomButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.leftBarButtonItem?.title = "OK"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor((self.collectionView.frame.size.width-10)/3)
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
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let url = NSURL(string: photo.url)
        let data = NSData(contentsOfURL: url!)
        cell.imageView.image = UIImage(data: data!)
        
        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
        
        if let index = find(selectedIndexes, indexPath) {
            cell.imageView.alpha = 0.05
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    // MARK: collection view
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
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
    
    // MARK: NSFetchedResultsControler delegate methods
    
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
        
        println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
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
        
        if selectedIndexes.isEmpty {
            
            newPhotoCollection()
        } else {
            deleteSelectedPhotos()
        }
    }
    
    func newPhotoCollection(){
        page += 1
        
        FlickrClient.sharedInstance().getPhotos(selectedPin, pageNumber: page){(result, error) in
            
            if error == nil {
                
                // Parse the array of photos dictionaries
                var photos = result?.map() {(dictionary: [String : AnyObject]) -> Photo in
                    
                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                    // set the relationship
                    photo.pin = self.selectedPin
                    
                    // save data
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                    return photo
                }
                
            } else {
                // TODO: handle error
                println("error")
            }
            
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
        
        selectedIndexes = [NSIndexPath]()
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
}
