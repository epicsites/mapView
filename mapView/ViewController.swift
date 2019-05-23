//
//  ViewController.swift
//  mapView
//
//  Created by Aleksandr on 3/22/19.
//  Copyright © 2019 Aleksandr. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {
    
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    let regionMeters: Double = 1000
    
    let pinView: UIImageView = {
        let pinView = UIImageView(image: UIImage(imageLiteralResourceName: "1"))
        pinView.translatesAutoresizingMaskIntoConstraints = false
        pinView.contentMode = .scaleAspectFit
        return pinView
    }()
    
    let centerCoordinateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let addAnnotationBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.setTitle("Pin", for: .normal)
        button.backgroundColor = UIColor(red: 1, green: 0.1, blue: 0.1, alpha: 0.5)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    let zoomUserLocationBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.setTitle("ML", for: .normal)
        button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 1, alpha: 0.5)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    let zoomPinnedLocationBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.setTitle("PL", for: .normal)
        button.backgroundColor = UIColor(red: 0.1, green: 1, blue: 0.1, alpha: 0.5)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        view.addSubview(pinView)
        view.addSubview(centerCoordinateLabel)
        view.addSubview(addAnnotationBtn)
        view.addSubview(zoomUserLocationBtn)
        view.addSubview(zoomPinnedLocationBtn)
        addAnnotationBtn.addTarget(self, action: #selector(addAnAnnotation), for: .touchUpInside)
        zoomUserLocationBtn.addTarget(self, action: #selector(centerViewOnUserLocation), for: .touchUpInside)
        zoomPinnedLocationBtn.addTarget(self, action: #selector(centerViewOnPinLocation), for: .touchUpInside)
        constraintViews()
        mapView.delegate = self
        mapView.mapType = .standard
        checkLocationServices()
    }
    
    func getCoordinateFromAddress(address: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            guard let placemarks = placemarks else { return }
            if error == nil && placemarks.count > 0 {
                let location = (placemarks.first?.location?.coordinate)!
                print("Currend address:\n\(address)\nlalitude - \(location.latitude)\nlongtitude - \(location.longitude)")
            }
        }
    }
    
    @objc func centerViewOnPinLocation() {
        guard let coordinate = mapView.annotations.last?.coordinate else { return }
        guard let userCoordinate = locationManager.location?.coordinate else { return }
        if !(coordinate == userCoordinate) {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @objc func addAnAnnotation() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let center = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(center, completionHandler: {
            placemarks, error in
            guard let placemarks = placemarks else { return }
            if error == nil && placemarks.count > 0 {
                guard let placeMark = placemarks.last else { return }
                let street = placeMark.thoroughfare ?? ""
                let number = placeMark.subThoroughfare ?? ""
                annotation.title = "\(street), \(number)"
                self.locationManager.stopUpdatingLocation()
            }
        })
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        print("\(mapView.annotations.first!.coordinate)")
        getCoordinateFromAddress(address: centerCoordinateLabel.text ?? "")
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    @objc func centerViewOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        }
        else { print("TURN IT ON") }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
        @unknown default:
            fatalError()
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterOfView(from: mapView)
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(center, completionHandler: {
            placemarks, error in
            guard let placemarks = placemarks else { return }
            if error == nil && placemarks.count > 0 {
                let placeMark = placemarks.last!
                let street = placeMark.thoroughfare ?? ""
                let number = placeMark.subThoroughfare ?? ""
                self.centerCoordinateLabel.text = "\(street), \(number)"
                self.locationManager.stopUpdatingLocation()
            }
        })
    }
    
    func getCenterOfView(from mapView: MKMapView) -> CLLocation {
        return CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        annotationView.canShowCallout = true
        annotationView.image = pinView.image
        annotationView.centerOffset = CGPoint(x: 0, y: -16)
        annotationView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return annotationView
    }
    
    func constraintViews() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: centerCoordinateLabel.topAnchor).isActive = true
        
        pinView.centerXAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.centerXAnchor).isActive = true
        pinView.centerYAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.centerYAnchor, constant: -16).isActive = true
        pinView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        pinView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        centerCoordinateLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        centerCoordinateLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        centerCoordinateLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        centerCoordinateLabel.heightAnchor.constraint(equalToConstant: view.frame.height / 10).isActive = true
        
        addAnnotationBtn.bottomAnchor.constraint(equalTo: centerCoordinateLabel.topAnchor, constant: -8).isActive = true
        addAnnotationBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8).isActive = true
        addAnnotationBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        addAnnotationBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        zoomUserLocationBtn.bottomAnchor.constraint(equalTo: addAnnotationBtn.topAnchor, constant: -8).isActive = true
        zoomUserLocationBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8).isActive = true
        zoomUserLocationBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        zoomUserLocationBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        zoomPinnedLocationBtn.bottomAnchor.constraint(equalTo: zoomUserLocationBtn.topAnchor, constant: -8).isActive = true
        zoomPinnedLocationBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8).isActive = true
        zoomPinnedLocationBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        zoomPinnedLocationBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
