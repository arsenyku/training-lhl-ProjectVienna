//
//  TabsViewController.swift
//  Project-Vienna
//
//  Created by asu on 2015-09-23.
//  Copyright © 2015 Rodrigo Moura Gonçalves. All rights reserved.
//

import Foundation

class TabsViewController: UITabBarController {
    var dataController: DataController
    
    init() {
        self.dataController = DataController()
        super.init(nibName: nil, bundle:nil)
    }

    
    override
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.dataController = DataController()
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }

    required
    init?(coder aDecoder: NSCoder) {
        self.dataController = DataController()
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
            
    	self.dataController.initializeDataIfNeeded()
        
        let cityController = self.viewControllers![0].childViewControllers[0]  as! CityViewController
        let mapController = self.viewControllers![1] as! MapAttractionsViewController

        cityController.setDataController(self.dataController)
        mapController.setDataController(self.dataController)
        
        cityController.delegate = mapController 

        LocationManager.sharedManager().startLocationManagerWithDelegate(mapController)
        
        self.delegate = mapController;
        
    }


}