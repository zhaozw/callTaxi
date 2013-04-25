//
//  CarInfo.h
//  CallTaxi
//
//  Created by Fan Lv on 13-4-24.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface CarInfo :  NSObject <MKAnnotation>

@property (nonatomic) double longitude;//经度
@property (nonatomic) double latitude;//纬度
@property (nonatomic) NSString* phoneNumber;//司机手机号码
@property (nonatomic) NSString* personalizedSignature;//个性签名
@property (nonatomic) int angle;//出租车形式方向
@property (nonatomic) int speed;//出租车速度
@property (nonatomic) double distanceFromUser;//该出租车距离用户的距离，单位是米.

@end
