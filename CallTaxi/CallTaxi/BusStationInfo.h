//
//  BusStationInfo.h
//  CallTaxi
//
//  Created by Fan Lv on 13-2-21.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface BusStationInfo : NSObject <MKAnnotation>

@property (strong,nonatomic) NSString *lineName;
@property (strong,nonatomic) NSString *stationName;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;


@end
