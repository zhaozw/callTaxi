//
//  CarInfo.m
//  CallTaxi
//
//  Created by Fan Lv on 13-4-24.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "CarInfo.h"

@implementation CarInfo
@synthesize longitude,latitude,phoneNumber,angle,speed,distanceFromUser;



- (NSString *)title
{
    return self.personalizedSignature;
}

- (NSString *)subtitle
{
    int distance  = (int)self.distanceFromUser;
    NSString *str =@"";
    if (distance ==  0)
    {
        str = self.phoneNumber;
    }
    else
    {
        str = [NSString stringWithFormat:@"%@,距离%d米",self.phoneNumber,(int)self.distanceFromUser];
        
    }
    return str;
}
- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = self.latitude;
    coordinate.longitude = self.longitude;
    return coordinate;
}
@end
