//
//  LocationPickerViewController.swift
//  BigMessenger
//
//  Created by user on 02.04.2022.
//

import UIKit
import CoreLocation
import MapKit

final class LocationPickerViewController: UIViewController {
    private var coordinates: CLLocationCoordinate2D?
    public var completion: ((CLLocationCoordinate2D)-> Void)?
    private var isPickable = true
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        if coordinates != nil {
            self.coordinates = coordinates
            self.isPickable = false
        }
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonTapped))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self,
                                                 action: #selector(didTapMap(gesture:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        }
        else {
            guard let coordinates = self.coordinates else {
                return
            }
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        view.addSubview(map)
    }
    @objc func sendButtonTapped() {
        guard let coordinates = coordinates else {
            return
        }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    @objc func didTapMap(gesture: UITapGestureRecognizer) {
        let locationInMap = gesture.location(in: map)
        let coordinates = map.convert(locationInMap, toCoordinateFrom: map)
        self.coordinates = coordinates
        //drop a pin on that location
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
}
