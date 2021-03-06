//
//  DataStack.m
//  Project-Vienna
//
//  Created by asu on 2015-09-21.
//  Copyright © 2015 Rodrigo Moura Gonçalves. All rights reserved.
//

#import "ApiKey.h"
#import "Constants.h"
#import "DataController.h"
#import "Location.h"
#import "City.h"
#import "User.h"
#import "Route.h"
#import "RouteSegment.h"

@interface DataController ()

@property (nonatomic, strong) NSManagedObjectModel *mom;
@property (nonatomic, strong) NSPersistentStoreCoordinator *psc;

@end

@implementation DataController

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // get momd url
        
        NSURL *momdURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        
        
        // init MOM
        self.mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
        
        
        // init PSC
        self.psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.mom];
        
        
        // get data store url
        
        NSString *storePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"datastore.sqlite"];
        
        NSLog(@"StorePath: %@", storePath);
        
        NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
        
        // add a NSSQLiteStoreType PS to the PSC
        
        NSError *storeError = nil;
        
        if (![self.psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&storeError]) {
            
            NSLog(@"Couldn't create persistant store %@", storeError);
        }
        
        // make a MOC
        
        self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        
        // set the MOCs PSC
        
        self.context.persistentStoreCoordinator = self.psc;
        
    }
    return self;
}

-(void) initializeDataIfNeeded{
    NSArray* cities = [self fetchEntitiesNamed:CITY_ENTITY_NAME];
    
    if (!cities || [cities count] < 1){
        [self createCities];
        [self createUser];
    }
}

-(NSArray *) fetchEntitiesNamed:(NSString*)entityName {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *result = [self.context executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"Unable to execute fetch request.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        
    } else {
        NSLog(@"fetched %lu entities", [result count]);
    }
    
    return result;
}

-(NSArray *)cities{
    return [self fetchEntitiesNamed:CITY_ENTITY_NAME];
}

-(void)loadRouteFromLatitude:(float)fromLatitude
               fromLongitude:(float)fromLongitude
                  toLocation:(Location *)toLocation
                        mode:(NSString*)mode
                  completion:(void (^)(Route *, NSError *))completionHandler{
    
    NSString *dataAddress = [NSString stringWithFormat:PLACE_ROUTE_API,
                             [NSString stringWithFormat:@"%.15f", fromLatitude],
                             [NSString stringWithFormat:@"%.15f", fromLongitude],
                             toLocation.placeId, mode, API_KEY];
    NSLog(@"dataAddress %@", dataAddress);
    
    [NSURLSession downloadFromAddress:dataAddress completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error){
            NSLog(@"Route Endpoint Download Error: %@", error);
            return;
        }
        
        id jsonData = [self jsonFromData:data];
        
        BOOL validData = [@"OK" isEqualToString: jsonData[ @"geocoded_waypoints" ][0][ @"geocoder_status" ] ];
       	validData = validData & [@"OK" isEqualToString: jsonData[ @"geocoded_waypoints" ][1][ @"geocoder_status" ] ];
        
        if (!validData){

            if (completionHandler)
                completionHandler(nil, error);

            return;
        }
        
        NSDictionary *legs = jsonData[ @"routes" ][0][@"legs"][0];
        NSDictionary *steps = legs[@"steps"];
        
        Route *route = [[Route alloc] init];
        
        route.durationText = legs[ @"duration" ][ @"text" ];
        
        for (NSDictionary *step in steps) {
            RouteSegment *routeSegment = [[RouteSegment alloc] init];
            routeSegment.startLatitude = step[@"start_location"][@"lat"] ;
            routeSegment.startLongitude = step[@"start_location"][@"lng"] ;
            routeSegment.endLatitude = step[@"end_location"][@"lat"] ;
            routeSegment.endLongitude = step[@"end_location"][@"lng"] ;
            
            [route addSegment:routeSegment];
        }
        
        if (completionHandler)
            completionHandler(route, error);
    }];
     

}

-(void)createUser{
    [NSEntityDescription insertNewObjectForEntityForName:USER_ENTITY_NAME
                                               inManagedObjectContext:self.context];

}

-(void)createCities{
    
    City *city = [NSEntityDescription insertNewObjectForEntityForName:CITY_ENTITY_NAME
                                                       inManagedObjectContext:self.context];
    
    city.name = @"New York";
    city.placeId = NEW_YORK_PLACE_ID;
    city.latitude = NEW_YORK_LATITUDE.floatValue;
    city.longitude = NEW_YORK_LONGITUDE.floatValue;

    [self loadDataWithNearbyApiForCity:city latitude:NEW_YORK_LATITUDE longitude:NEW_YORK_LONGITUDE radius:@"50000" type:@"museum"];
    [self loadDataWithNearbyApiForCity:city latitude:NEW_YORK_LATITUDE longitude:NEW_YORK_LONGITUDE radius:@"50000" type:@"park"];
    [self loadDataWithNearbyApiForCity:city latitude:NEW_YORK_LATITUDE longitude:NEW_YORK_LONGITUDE radius:@"50000" type:@"shopping_mall"];
    [self loadDataWithNearbyApiForCity:city latitude:NEW_YORK_LATITUDE longitude:NEW_YORK_LONGITUDE radius:@"50000" type:@"stadium"];
    
    city = [NSEntityDescription insertNewObjectForEntityForName:CITY_ENTITY_NAME
                                               inManagedObjectContext:self.context];
    
    city.name = @"London";
    city.placeId = LONDON_PLACE_ID;
    city.latitude = LONDON_LATITUDE.floatValue;
    city.longitude = LONDON_LONGITUDE.floatValue;
    
    [self loadDataWithNearbyApiForCity:city latitude:LONDON_LATITUDE longitude:LONDON_LONGITUDE radius:@"50000" type:@"museum"];
    [self loadDataWithNearbyApiForCity:city latitude:LONDON_LATITUDE longitude:LONDON_LONGITUDE radius:@"50000" type:@"park"];
    [self loadDataWithNearbyApiForCity:city latitude:LONDON_LATITUDE longitude:LONDON_LONGITUDE radius:@"50000" type:@"shopping_mall"];
    [self loadDataWithNearbyApiForCity:city latitude:LONDON_LATITUDE longitude:LONDON_LONGITUDE radius:@"50000" type:@"stadium"];
    
    city = [NSEntityDescription insertNewObjectForEntityForName:CITY_ENTITY_NAME
                                               inManagedObjectContext:self.context];
    
    city.name = @"Vancouver";
    city.placeId = VANCOUVER_PLACE_ID;
    city.latitude = VANCOUVER_LATITUDE.floatValue;
    city.longitude = VANCOUVER_LONGITUDE.floatValue;
    
    [self loadDataWithNearbyApiForCity:city latitude:VANCOUVER_LATITUDE longitude:VANCOUVER_LONGITUDE radius:@"50000" type:@"museum"];
    [self loadDataWithNearbyApiForCity:city latitude:VANCOUVER_LATITUDE longitude:VANCOUVER_LONGITUDE radius:@"50000" type:@"park"];
    [self loadDataWithNearbyApiForCity:city latitude:VANCOUVER_LATITUDE longitude:VANCOUVER_LONGITUDE radius:@"50000" type:@"shopping_mall"];
    [self loadDataWithNearbyApiForCity:city latitude:VANCOUVER_LATITUDE longitude:VANCOUVER_LONGITUDE radius:@"50000" type:@"stadium"];
    
    
    [self saveContext];
    
    
}

-(void)saveContext{
    NSError *saveError = nil;
    [self.context save:&saveError];
    
    if (saveError)
        NSLog(@"Error while saving context: %@", saveError);
}

-(void) loadDataWithPlacePhotosApiForLocation:(Location*)location completion:(void (^)(UIImage *image, NSError *error))completionHandler {
    
    NSString *dataAddress = [NSString stringWithFormat:PLACE_PHOTOS_API, MAX_HEIGHT, location.photoReference, API_KEY];
    NSLog(@"dataAddress %@", dataAddress);
    
    [NSURLSession downloadFromAddress:dataAddress completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error){
            NSLog(@"Detail Endpoint Download Error: %@", error);
            return;
        }
       
        UIImage *downloadedImage = [UIImage imageWithData:data];
        
        if (completionHandler) {
            completionHandler(downloadedImage,error);
        }
    }];
}

-(void) loadDataWithPlaceDetailApiForLocation:(Location*)location {
    NSString *dataAddress = [NSString stringWithFormat:PLACE_DETAILS_API, location.placeId, API_KEY];
    NSLog(@"dataAddress %@", dataAddress);
    
    [NSURLSession downloadFromAddress:dataAddress completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self processPlaceDetailForLocation:location data:data response:response error:error];
    }];
    
}

-(void) loadDataWithRadarApiForLatitude:(NSString*)latitude longitude:(NSString*)longitude
                                 radius:(NSString*)radius type:(NSString*)type {
    
    NSString *dataAddress = [NSString stringWithFormat:RADAR_API, latitude, longitude, radius, type, API_KEY];
    NSLog(@"dataAddress %@", dataAddress);
    
    [NSURLSession downloadFromAddress:dataAddress completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self processLocationsForCity:nil data:data response:response error:error];
    }];
    
}

-(void) loadDataWithNearbyApiForCity:(City*)city
                              latitude:(NSString*)latitude longitude:(NSString*)longitude
                                radius:(NSString*)radius type:(NSString*)type {
    
    NSString *dataAddress = [NSString stringWithFormat:NEARBY_API, latitude, longitude, radius, type, API_KEY];
    NSLog(@"dataAddress %@", dataAddress);
    
    
    [NSURLSession downloadFromAddress:dataAddress completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self processLocationsForCity:city data:data response:response error:error];
    }];
    
}

- (void)loadImageFromLocation:(Location *)location completion:(void (^)(UIImage *image, NSError *error))completionHandler {
    [self loadDataWithPlacePhotosApiForLocation:location completion:completionHandler];
}


-(void)processPlaceDetailForLocation:(Location*)location data:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error{
    if (error){
        NSLog(@"Detail Endpoint Download Error: %@", error);
        return;
    }
    
    id jsonData = [self jsonFromData:data];
    
    NSLog(@"placeDetail %@", jsonData);
    
    NSDictionary *placeDetailData = jsonData[ @"result" ];
    
    location.name = placeDetailData[ @"name" ];
    
    location.address = placeDetailData[ @"formatted_address" ];
    location.phone = placeDetailData[ @"formatted_phone_number" ];
    location.hours = placeDetailData[ @"opening_hours" ];
    location.rating = [(NSString*)placeDetailData[ @"rating" ] floatValue];
    location.type = placeDetailData[ @"types" ][0];
    location.website = placeDetailData[ @"website" ];
    location.iconURL = placeDetailData[ @"icon" ];
    
    if (placeDetailData[@"photos"]) {
        location.photoReference = placeDetailData[ @"photos" ][0][ @"photo_reference" ];
    }

    [self saveContext];
    
    
}

-(void)processLocationsForCity:(City*)city data:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error{
    if (error){
        NSLog(@"Radar Endpoint Download Error: %@", error);
        return;
    }
    
    NSDictionary *jsonData = [self jsonFromData:data];
    
    if ([jsonData count] == 0) {
        NSLog(@"No jsonData received. %@", jsonData);
    }
    
    NSArray *placesData = jsonData[ @"results" ];
    
    NSMutableArray *locations = [[NSMutableArray alloc] init];
    
    for (NSDictionary* placeData in placesData) {
        NSString* placeLatitude = placeData[ @"geometry" ][ @"location" ][ @"lat" ];
        NSString* placeLongitude = placeData[ @"geometry" ][ @"location" ][ @"lng" ];
        NSString* placeId = placeData[ @"place_id" ];
        
        NSLog(@"%@ -- %@ -- %@", placeLatitude, placeLongitude, placeId);
        
        Location *location = [NSEntityDescription insertNewObjectForEntityForName:LOCATION_ENTITY_NAME
                                                           inManagedObjectContext:self.context];
        
        
        location.placeId = placeId;
        location.latitude = placeLatitude.floatValue;
        location.longitude = placeLongitude.floatValue;
        
        location.city = city;
        
        [locations addObject:location];
    }
    
    [self saveContext];
    
    NSLog(@"Downloaded %lu locations", [locations count]);
    
    for (Location *locationEntity in locations) {
        [self loadDataWithPlaceDetailApiForLocation:locationEntity];
    }
    
}

-(id)jsonFromData:(NSData*)data{
    NSError *jsonError = nil;
    id jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    
    if (jsonError){
        NSLog(@"Radar Endpoint Deserialization Error: %@", jsonError);
        return nil;
    }
    return jsonData;
}


@end
