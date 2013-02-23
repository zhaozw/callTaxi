//
//  Common.h
//  CallTaxi
//
//  Created by Fan Lv on 13-2-9.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>




@interface Common : NSObject

+ (UIImage *)currentPostionBtnImgGreyButtonHighlight;
+ (UIImage *)currentPostionBtnImgGreyButton;
+ (UIImage *)currentPostionBtnImgLocationGrey;
+ (UIImage *)currentPostionBtnImgLocationBlue;
+ (UIImage *)currentPostionBtnImgLocationHeadingBlue;
+ (UIImage *)currentPostionBtnImgTransport;
+ (UIImage *)callPhoneNumberImage;



+ (BOOL)isExistenceNetwork;

+ (NSData *) GetVersion;

+ (NSString *)ByteToBinaryString:(Byte) byte;

+ (NSString *)ShortToBinaryString:(ushort)number;

+ (NSInteger)BinaryStringToInt:(NSString *)binaryString;

+ (BOOL)isMobileNumber:(NSString *)mobileNum;

+ (NSData *)reversedData:(NSData *)data;

+ (BOOL)makeCall:(NSString *)number;


@end
