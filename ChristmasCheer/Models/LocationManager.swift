//
//  LocationManager.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/22/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: Properties

    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = 50
        locationManager.distanceFilter = 750
        return locationManager
        }()
    
    var locationUpdatedBlock: (location: CLLocation) -> Void = { _ in }
    var locationStatusUpdated: (approved: Bool) -> Void = { _ in }
    
    let geocoder = CLGeocoder()
    
    // MARK: Singleton
    
    class var sharedManager: LocationManager {
        struct Singleton {
            static let instance = LocationManager()
        }
        return Singleton.instance
    }
    
    // MARK: Status
    
    class var locationServicesEnabled: Bool {
        get {
            var enabled = false
            switch CLLocationManager.authorizationStatus() {
            case .Authorized:
                fallthrough
            case .AuthorizedWhenInUse:
                enabled = true
            case .NotDetermined:
                break
            case .Denied:
                break
            case .Restricted:
                break
            }
            return enabled
        }
    }
    
    class func requestPermissions() {
        self.sharedManager.locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: Start / Stop Listening

    class func listenForPlacemark(update: CLPlacemark -> Void) {
        startListeningForLocationWithUpdatedBlock { location in
            sharedManager.geocoder.reverseGeocodeLocation(location) { (placemarks, error) -> Void in
                guard let placemark = placemarks?.first else { return }
                update(placemark)
            }
        }
    }
    
    class func startListeningForLocationWithUpdatedBlock(locationUpdatedBlock:(location: CLLocation) -> Void) {
        guard locationServicesEnabled else {
            fatalError("Must ensure authorization before you begin listening!")
        }
        
        sharedManager.locationUpdatedBlock = locationUpdatedBlock
        sharedManager.locationManager.startUpdatingLocation()
    }
    
    class func stopListening() {
        sharedManager.locationManager.stopUpdatingLocation()
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationUpdatedBlock(location: location)
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        locationStatusUpdated(approved: LocationManager.locationServicesEnabled)
    }
}
