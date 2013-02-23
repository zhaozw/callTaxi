//
//  TaxiInfo.h
//  CallTaxi
//
//  Created by Fan Lv on 13-2-18.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TaxiInfo : NSObject <MKAnnotation>




@property (nonatomic) double longitude;//经度
@property (nonatomic) double latitude;//纬度
@property (nonatomic) NSString* ipAddress;//IP地址
@property (nonatomic) Byte taxiState;//出租车状态
@property (nonatomic) NSString* phoneNumber;//司机手机号码
@property (nonatomic) NSString* licenseplatenumber;//出租车牌号
@property (nonatomic) NSString* taxiType;//出租车类型
@property (nonatomic) int star;//出租车星级
@property (nonatomic) int angle;//出租车形式方向
@property (nonatomic) int speed;//出租车速度
@property (nonatomic) double distanceFromUser;//该出租车距离用户的距离，单位是米，这个我特意加的。

@end
