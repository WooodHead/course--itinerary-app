//
//  TripsModelController.swift
//  Itinerary
//
//  Created by Brian Sipple on 7/7/19.
//  Copyright © 2019 Brian Sipple. All rights reserved.
//

import Foundation


protocol TripsModelControllerObserver: class {
    func modelController(_ controller: TripsModelController, didUpdate trips: [Trip])
}


final class TripsModelController {
    private let dataLoader: DataLoader
    private var tripsObservers: [TripsModelControllerObserver] = []
    
    private(set) var trips: [Trip] = [] {
        didSet { notifyTripsObservers() }
    }

    
    init(dataLoader: DataLoader = DataLoader()) {
        self.dataLoader = dataLoader
    }
}

// MARK: - Core Methods
extension TripsModelController {
    
    typealias CompletionHandler = (Result<[Trip], Error>) -> Void
    
    
    func addTripsObserver(_ observer: TripsModelControllerObserver) {
        tripsObservers.append(observer)
    }
    
    
    func removeTripsObserver(_ observer: TripsListViewController) {
//        tripsObservers.remove(at: index)
    }
    
    
    func loadTrips(then completionHandler: CompletionHandler? = nil) {
        let url = Endpoint.Trip.localURL
        
        dataLoader.load(from: url) { [weak self] dataResult in
            guard let self = self else { return }
            
            switch dataResult {
            case .success(let data):
                let decoder = JSONDecoder()
                
                do {
                    self.trips = try decoder.decode([Trip].self, from: data)
                    completionHandler?(.success(self.trips))
                } catch {
                    print("Error while attempting to decode trips: \(error.localizedDescription)")
                    completionHandler?(.failure(error))
                }
            case .failure(let error):
                print("Error while attempting to load trips: \(error.localizedDescription)")
                completionHandler?(.failure(error))
            }
            
            let dummyTrips = [
                Trip(title: "Trip to NYC", shortDescription: "🗽⚡️"),
                Trip(title: "Trip to Chicago", shortDescription: "🏰⚡️"),
                Trip(title: "Trip to London", shortDescription: "🇬🇧⚡️"),
                Trip(title: "Trip to Paris", shortDescription: "🇫🇷⚡️"),
            ]

            self.trips = dummyTrips
        }
    }
    
    
    
    func create(_ trip: Trip, then completionHandler: CompletionHandler? = nil) {
        self.trips.append(trip)
        completionHandler?(.success(trips))
    }
    
    
    func update(_ updatedTrip: Trip, then completionHandler: CompletionHandler? = nil) {
        
    }
    
    
    func deleteTrip(withID: Trip, then completionHandler: CompletionHandler? = nil) {
        
    }
}


// MARK: - Private Helpers

extension TripsModelController {
    
    func notifyTripsObservers() {
        tripsObservers.forEach {
            $0.modelController(self, didUpdate: trips)
        }
    }
}
