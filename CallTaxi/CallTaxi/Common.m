//
//  Common.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-9.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "Common.h"
#import "Reachability.h"
#import "UIDevice+IdentifierAddition.h"
#import "UIDevice+IdentifierAddition.h"
#import "NSData+Hex.h"
#import "NSString+Help.h"

@implementation Common

+ (UIImage *)currentPostionBtnImgGreyButtonHighlight
{
   return [UIImage imageNamed:@"greyButtonHighlight.png"];
}
+ (UIImage *)currentPostionBtnImgGreyButton
{
    return [UIImage imageNamed:@"greyButton.png"];
}
+ (UIImage *)currentPostionBtnImgLocationGrey
{
    return [UIImage imageNamed:@"LocationGrey.png"];
}
+ (UIImage *)currentPostionBtnImgLocationBlue
{
    return [UIImage imageNamed:@"LocationBlue.png"];
}
+ (UIImage *)currentPostionBtnImgLocationHeadingBlue
{
    return [UIImage imageNamed:@"LocationHeadingBlue.png"];
}

+ (UIImage *)currentPostionBtnImgTransport
{
    return [UIImage imageNamed:@"transport.png"];
}

+ (UIImage *)callPhoneNumberImage
{
    return [UIImage imageNamed:@"Call.png"];

}

+ (NSData *)reversedData:(NSData *)data
{
    NSMutableData *reversedData =[[NSMutableData alloc] init];
    NSUInteger len = [data length];
    Byte *dataArray = (Byte*)malloc(len);
    memcpy(dataArray, [data bytes], len);
    
    for (int i = len-1; i >= 0; i--)
    {
        [reversedData appendBytes:&dataArray[i] length:sizeof(Byte)];
    }
  
    return reversedData;
}

//拨打电话的方法
+ (BOOL)makeCall:(NSString *)number
{
    NSURL *telURL = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@", number]];
    return  [[UIApplication sharedApplication] openURL:telURL];
   // [self AfterCallTaxi];
}

+ (BOOL)isMobileNumber:(NSString *)mobileNum
{
    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     * 联通：130,131,132,152,155,156,185,186
     * 电信：133,1349,153,180,189
     */
    NSString * MOBILE = @"^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";
    /**
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     12         */
    NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$";
    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,152,155,156,185,186
     17         */
    NSString * CU = @"^1(3[0-2]|5[256]|8[56])\\d{8}$";
    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,180,189
     22         */
    NSString * CT = @"^1((33|53|8[09])[0-9]|349)\\d{7}$";
    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
    // NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
    
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    
    if (([regextestmobile evaluateWithObject:mobileNum] == YES)
        || ([regextestcm evaluateWithObject:mobileNum] == YES)
        || ([regextestct evaluateWithObject:mobileNum] == YES)
        || ([regextestcu evaluateWithObject:mobileNum] == YES))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

+(BOOL)isExistenceNetwork
{
	BOOL isExistenceNetwork;
    Reachability *r = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    switch ([r currentReachabilityStatus])
    {
        case NotReachable:
			isExistenceNetwork=FALSE;
            break;
        case ReachableViaWWAN:
        case ReachableViaWiFi:
			isExistenceNetwork=TRUE;
            break;
    }
	return isExistenceNetwork;
    
}


+ (NSString *)ByteToBinaryString:(Byte) byte
{
    NSMutableString *strtes = [[NSMutableString alloc] init];
    for(NSInteger numberCopy = byte; numberCopy > 0; numberCopy >>= 1)
    {
        // Prepend "0" or "1", depending on the bit
        [strtes insertString:((numberCopy & 1) ? @"1" : @"0") atIndex:0];
    }
    
    NSString  *padString = [strtes stringByPaddingTheLeftToLength:8 withString:@"0" startingAtIndex:0];

    return padString;
}

//static NSString * binaryStringFromInteger( ushort number )
+ (NSString *)ShortToBinaryString:(ushort)number
{
    NSMutableString * string = [[NSMutableString alloc] init];
    
    int spacing = pow( 2, 3 );
    int width = ( sizeof( number ) ) * spacing;
    int binaryDigit = 0;
    int integer = number;
    
    while( binaryDigit < width )
    {
        binaryDigit++;
        [string insertString:( (integer & 1) ? @"1" : @"0" )atIndex:0];
//        if( binaryDigit % spacing == 0 && binaryDigit != width )
//        {
//            [string insertString:@" " atIndex:0];
//        }
        integer = integer >> 1;
    }
    
    return string;
}

- (int) binaryStringToInt2: (NSString*) binaryString;
{
    unichar aChar;
    int value = 0;
    int index;
    for (index = 0; index<[binaryString length]; index++)
    {
        aChar = [binaryString characterAtIndex: index];
        if (aChar == '1')
            value += 1;
        if (index+1 < [binaryString length])
            value = value<<1;
    }
    return value;
}

+ (NSInteger)BinaryStringToInt:(NSString *)binaryString
{
    long v = strtol([binaryString UTF8String], NULL, 2);
    return v;
}


+ (NSData *) GetVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    //CFShow((__bridge CFTypeRef)(infoDictionary));
    // app版本
    NSString *Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSData *data=[Version dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}






@end
