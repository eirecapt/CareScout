//
//  InterfaceController.swift
//  CareScout WatchKit Extension
//
//  Created by Michael Pangburn on 11/3/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import WatchKit
import NightscoutKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var bloodGlucoseLabel: WKInterfaceLabel!

    var manager: NightscoutDataManager?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        let url = URL(string: "https://cgmpangburn.herokuapp.com")!
        NightscoutDownloaderCredentials.validate(url: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let credentials):
                self.manager = NightscoutDataManager(downloaderCredentials: credentials, dataStore: .allDataStore())
                self.update()
            case .failure(let error):
                // TODO: handle error
                break
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func update() {
        updateStatus(then: updateGlucose)
    }

    func updateStatus(then next: @escaping () -> Void) {
        manager?.downloader.fetchStatus { _ in next() }
    }

    func updateGlucose() {
        manager?.downloader.fetchMostRecentEntries(count: 1) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let entries):
                guard let mostRecent = entries.first else {
                    return // TODO: requested one but got none!
                }
                let unit = self.manager?.dataStore.fetchedStatus?.settings.bloodGlucoseUnits ?? .milligramsPerDeciliter

                let displayString: String
                switch mostRecent.converted(to: unit).source {
                case .meter:
                    displayString = String(describing: mostRecent.glucoseValue.valueString)
                case .sensor(trend: let trend):
                    displayString = "\(mostRecent.glucoseValue.valueString)\(trend)"
                }
                self.bloodGlucoseLabel.setText(displayString)
            case .failure(let error):
                // TODO: handle error
                break
            }
        }
    }
}
