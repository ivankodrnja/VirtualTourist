//
//  TravelLoactionsMapViewController.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 12/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import UIKit
import MapKit

class TravelLoactionsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // method for getting the map's state before app exited
        restoreMapRegion(false)
        
        // long press gesture recognizer instance
        var longPressGR = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        mapView.addGestureRecognizer(longPressGR)
        
        // this class is MKMapViewDelegate
        self.mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
}

/**
*  This extension comforms to the MKMapViewDelegate protocol. This allows
*  the view controller to be notified whenever the map region changes. So
*  that it can save the new region.
*/

extension TravelLoactionsMapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
    @IBAction func longTapAction(sender: UILongPressGestureRecognizer) {
        /*
        //Get the current state of the GestureRecognizer
        let state = sender.state
        
        //If the touch has begun recognzing (after 0.5s)
        if state == .Began {
            
            //Get the spot that was pressed.
            let tapPoint: CGPoint = sender.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
            
            //Create an annotation object
            droppedPin = LocationPin(pin: nil, coordinate: touchMapCoordinate)
            
            //Add annotation to map
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotation(self.droppedPin)
            })
        }
            
            //If the touch has moved / changed once the touch has began
        else if state == .Changed {
            
            //Check to make sure the pin has dropped
            if droppedPin != nil {
                
                //Get the coordinates from the map where we dragged over
                let tapPoint: CGPoint = sender.locationInView(mapView)
                let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
                
                //Update the pin view
                dispatch_async(dispatch_get_main_queue(), {
                    self.droppedPin.coordinate = touchMapCoordinate
                })
            }
        }
            
            //If the touch has now ended
        else if state == .Ended {
            //Create the Pin entity
            let pin = Pin(coords: droppedPin.coordinate, context: sharedContext)
            
            //Assign the pin to the droppedPin
            droppedPin.pin = pin
            //Save pin and fetch images...
        }
        */
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        
        if gestureRecognizer.state == .Began{
        
        var touchPoint = gestureRecognizer.locationInView(self.mapView)
        var newCoord:CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
        
        var newAnotation = MKPointAnnotation()
        newAnotation.coordinate = newCoord
        mapView.addAnnotation(newAnotation)
        }
    }

    // MARK: - Map delegate methods
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinColor = .Red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
}

