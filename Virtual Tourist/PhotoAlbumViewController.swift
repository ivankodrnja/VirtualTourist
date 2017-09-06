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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    var selectedPin : Pin!
    var page : Int = 1
    
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
        
    }
    */
    // Do not worry about this initializer. I has to be implemented
    // because of the way Swift interfaces with an Objective C
    // protocol called NSArchiving. It's not relevant.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected"
    var selectedIndexes = [IndexPath]()
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        setMapRegion(true)
        
        self.mapView.addAnnotation(selectedPin)
        self.mapView.isZoomEnabled = false
        self.mapView.isScrollEnabled = false
        self.mapView.isUserInteractionEnabled = false
        
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = []
        fr.predicate = NSPredicate(format: "pin == %@", self.selectedPin)
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        
        // this class is NSFetchedResultsControllerDelegate
        /*
        fetchedResultsController.delegate = self
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        if let error = error {
            print("Error: \(error.localizedDescription)")
            self.showAlertView("There was a problem with this pin. Please go back to the map and drop a new one.")
        }
         */
        // check if there are available photos associted with the pin, and if no act accordingly
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            self.noImagesLabel.isHidden = false
            bottomButton.isEnabled = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    

    /*
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    */
    
    // MARK: - Map
    
    func setMapRegion(_ animated: Bool) {

        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        
        let savedRegion = MKCoordinateRegion(center: selectedPin.coordinate, span: span)
        
        mapView.setRegion(savedRegion, animated: animated)
    }
    
    // MARK: - Configure Cell
    
    func configureCell(_ cell: PhotoCell, atIndexPath indexPath: IndexPath) {
        
        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
        
        if let _ = selectedIndexes.index(of: indexPath) {
            cell.imageView.alpha = 0.5
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController?.sections![section] 
        
        return sectionInfo!.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        
        // reset pevious images in the xell
        cell.imageView.image = nil
        
        // makeing sure the activity indicator is animating
        cell.activityView.startAnimating()
        
        // if there is an image, update the cell appropriately
        if photo.image != nil {
            
            cell.activityView.stopAnimating()
            cell.imageView.alpha = 0.0
            cell.imageView.image = photo.image
            
            UIView.animate(withDuration: 0.2,
                animations: { cell.imageView.alpha = 1.0 })
        }
        // modify the cell
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController!.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        //Disallow selection if the cell is waiting for its image to appear.
        if cell.activityView.isAnimating {
            
            return false
        }
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell

        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        updateBottomButton()
    }
    
    // MARK: - NSFetchedResultsControler delegate methods
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type{
            
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break

        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        //Check to make sure UI elements are correctly displayed.
        if controller.fetchedObjects?.count > 0 {
            
            noImagesLabel.isHidden = true
            bottomButton.isEnabled = true
        }
        //Make the relevant updates to the collectionView once Core Data has finished its changes.
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
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
            DispatchQueue.main.async{
                /*
                do {
                    try self.stack.saveContext()
                } catch {
                    print("Error: \(String(describing: error.localizedDescription))")
                }
                 */
            }
        }
    }
    
    // MARK: - Helpers
    
    func newPhotoCollection(){
        bottomButton.isEnabled = false
        
        page += 1
        
        // delete existing photos
        for photo in fetchedResultsController?.fetchedObjects as! [Photo] {
            stack.context.delete(photo)
        }
        // save on the main thread (part of getting Core Data thread safe)
        DispatchQueue.main.async{
            /*
            do {
                try self.stack.saveContext()
            } catch {
                print("Error: \(String(describing: error.localizedDescription))")
            }
             */
        }
        
        FlickrClient.sharedInstance().getPhotos(selectedPin, pageNumber: page){(result, error) in
            
            if error == nil {
                
                // Parse the array of photos dictionaries
                DispatchQueue.main.async{
                    _ = result?.map() {(dictionary: [String : AnyObject]) -> Photo in
                        
                        let photo = Photo(dictionary: dictionary, pin: self.selectedPin, context: self.stack.context)
                        // set the relationship
                        //photo.pin = self.selectedPin
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
                                    self.bottomButton.isEnabled = true
                                })
                                
                            } else {
                                // We won't alert the user
                                print("Error: \(String(describing: error?.localizedDescription))")
                                self.bottomButton.isEnabled = true
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
        
    }
    
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController?.object(at: indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            stack.context.delete(photo)
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
    
    
    func showAlertView(_ errorMessage: String?) {
        
        let alertController = UIAlertController(title: nil, message: errorMessage!, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel) {(action) in
            
            
        }
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true){
            
        }
        
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
    
}
