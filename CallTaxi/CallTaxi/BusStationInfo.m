//
//  BusStationInfo.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-21.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "BusStationInfo.h"

@implementation BusStationInfo

@synthesize stationName,lineName;

@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

//加上共青的GPS位移，只有共青的公交，所以写死。
- (double)latitude
{
    return _latitude - 0.00278;
}

- (double)longitude
{
    return _longitude + 0.004999;
}

- (NSString *)title
{
    return self.stationName;
}

- (NSString *)subtitle
{
    return lineName;
}
- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = self.latitude;
    coordinate.longitude = self.longitude;
    return coordinate;
}


@end
