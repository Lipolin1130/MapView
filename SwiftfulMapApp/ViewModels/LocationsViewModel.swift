//
//  LocationsViewModel.swift
//  SwiftfulMapApp
//
//  Created by Nick Sarno on 11/27/21.
//

import Foundation
import MapKit
import SwiftUI
import FirebaseFirestore
import FirebaseStorage


class LocationsViewModel: ObservableObject {
    @Published var findString = ""
    // All loaded locations
    @Published var locations: [Location] = []
    
    // Current location on map
    @Published var mapLocation: Location {
        didSet {
            updateMapRegion(location: mapLocation)
        }
    }
//    @Published var mapLocation: Location =
    
    // Current region on map
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion()
    let mapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    
    // Show list of locations
    @Published var showLocationsList: Bool = false
    
    // Show location detail via sheet
    @Published var sheetLocation: Location? = nil
    init() {
//        self.locations = LocationsDataService.locations
        self.mapLocation = LocationsDataService.locations.first!
//        self.locations = [Location]()
//            let locations = LocationsDataService.locations
//            self.locations = locations
//            self.mapLocation = locations.first!
//            self.updateMapRegion(location: locations.first!)
    }
    
    private func updateMapRegion(location: Location) {
        withAnimation(.easeInOut) {
            mapRegion = MKCoordinateRegion(
                center: location.coordinates,
                span: mapSpan)
        }
    }
    
    func toggleLocationsList() {
        withAnimation(.easeInOut) {
            //            showLocationsList = !showLocationsList
            showLocationsList.toggle()
        }
    }
    
    func showNextLocation(location: Location) {
        withAnimation(.easeInOut) {
            mapLocation = location
            showLocationsList = false
        }
    }
    
    func nextButtonPressed() {
        // Get the current index
        guard let currentIndex = locations.firstIndex(where: { $0 == mapLocation }) else {
            print("Could not find current index in locations array! Should never happen.")
            return
        }
        
        // Check if the currentIndex is valid
        let nextIndex = currentIndex + 1
        guard locations.indices.contains(nextIndex) else {
            // Next index is NOT valid
            // Restart from 0
            guard let firstLocation = locations.first else { return }
            showNextLocation(location: firstLocation)
            return
        }
        
        // Next index IS valid
        let nextLocation = locations[nextIndex]
        showNextLocation(location: nextLocation)
    }
    
    func getData(){
        self.locations.removeAll()
        Firestore.firestore().collection("Location").getDocuments() { (querySnapshot, err) in
            
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let cityName = data["cityName"] as? String ?? ""
                    let description = data["description"] as? String ?? ""
                    let link = data["link"] as? String ?? ""
                    let name = data["name"] as? String ?? ""
                    let coordinate = data["coordinate"] as? GeoPoint
                    let imageNames = data["imageNames"] as? [String] ?? []
                    
                    self.locations.append(Location(name: name, cityName: cityName, coordinates: CLLocationCoordinate2D(latitude: coordinate?.latitude ?? 0, longitude: coordinate?.longitude ?? 0), description: description, imageNames: imageNames,link: link))
                    
//                    print("\(document.documentID) => \(document.data())")
                }
                self.mapLocation = self.locations.first!
            }
        }
    }
    func getUrl(findNames: String) -> String {
        let storage = Storage.storage().reference()
            storage.child("location/\(findNames).jpg").downloadURL{(url, err) in
                if err != nil{
                    print("didn't get the photo")
                    print((err?.localizedDescription)!)
                    return
                }
                self.findString = ("\(url!)")
            }
        return findString
    }
}
