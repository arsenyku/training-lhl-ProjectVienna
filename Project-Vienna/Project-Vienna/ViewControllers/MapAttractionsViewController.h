//
//  SecondViewController.h
//  Project-Vienna
//
//  Created by Rodrigo Moura Gonçalves on 21/09/15.
//  Copyright © 2015 Rodrigo Moura Gonçalves. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataController.h"
#import "CityViewController.h"
#import <CoreLocation/CoreLocation.h>


@interface MapAttractionsViewController : UIViewController <CitySelectionDelegate, CLLocationManagerDelegate, UITabBarControllerDelegate>
-(void)setDataController:(DataController *)dataController;

@end

