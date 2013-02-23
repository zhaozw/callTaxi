//
//  BusInfo.h
//  CallTaxi
//
//  Created by Fan Lv on 13-2-21.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface BusInfo : NSObject <MKAnnotation>

@property (nonatomic) double longitude;//经度
@property (nonatomic) double latitude;//纬度
@property (nonatomic) NSString* IMEI;
@property (nonatomic) NSString* busName;
@property (nonatomic) int angle;
@property (nonatomic) int speed;

@end
