//
//  OperateAgreement.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-11.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "OperateAgreement.h"
#import "Common.h"
#import "UIDevice+IdentifierAddition.h"
#import "NSString+Help.h"
#import "NSData+Hex.h"
#import "fileOperate.h"

@implementation OperateAgreement



+ (void)SetTaxiServerHost:(NSString *)taxiServerHost 
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:taxiServerHost forKey:TAXI_SERVER_HOST];
}

+ (NSString *)TaxiServerHost
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *taxiServerHost = [ud objectForKey:TAXI_SERVER_HOST];
    
    if (self.UserPhoneNumber.length != 11)
    {
        return nil;
    }
    
    if ([[self ServerCityName] isEqualToString:@"九江市"])
    {
        NSString *phoneNumberHead = [self.UserPhoneNumber substringToIndex:3];
        
        if ([phoneNumberHead isEqualToString:@"130"]||[phoneNumberHead isEqualToString:@"131"]||[phoneNumberHead isEqualToString:@"132"]||[phoneNumberHead isEqualToString:@"145"]||[phoneNumberHead isEqualToString:@"155"]||[phoneNumberHead isEqualToString:@"156"]||[phoneNumberHead isEqualToString:@"185"]||[phoneNumberHead isEqualToString:@"186"])
        {
            taxiServerHost = SERVER_ADDRESS_JIUJIANG_L; 
        }
        else
        {
            taxiServerHost = SERVER_ADDRESS_JIUJIANG_D;
        }
    }
    else  //占时这样写。
    {
        return SERVER_ADDRESS_WUHAN;
    }

    
    //NSLog(@"%@",taxiServerHost);
    return taxiServerHost;
}

+ (NSString *)BusServerHost
{
    //return @"gqcbus.cityofcar.com";
    return @"219.140.165.6";
}

+ (void)SetUserPhoneNumber:(NSString *)phoneNumber
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:phoneNumber forKey:USER_PHONENUMBER];
}

+ (NSString *)UserPhoneNumber
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *phoneNumber = [ud valueForKey:USER_PHONENUMBER];
//    if (phoneNumber.length == 0)
//    {
//      phoneNumber = @"18602789588";
//    }
    return phoneNumber;
}

+ (void)SetServerCityName:(NSString *)cityName
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:cityName forKey:SERVER_CITY_NAME];
}

+ (NSString *)ServerCityName
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *cityName = [ud valueForKey:SERVER_CITY_NAME];
    if (cityName.length == 0)
    {
        cityName = @"九江市";
    }
    return cityName;
}

+ (void)SetReferrer:(NSString *)peopleName
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:peopleName forKey:USER_REFERRER];

}

+ (NSString *)Referrer
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *peopleName = [ud valueForKey:USER_REFERRER];
    return peopleName;
}

+ (void)SetServerPhoneNumber:(NSString *)phoneNumber
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:phoneNumber forKey:SERVER_PHONENUMBER];
}

+ (NSString *)ServerPhoneNumber
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *phoneNumber = [ud valueForKey:SERVER_PHONENUMBER];
    return phoneNumber;
}

+ (void)SetRange:(NSInteger)range
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:range forKey:SEARCHTAXI_RANGE];

}

+ (NSInteger)Range
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSInteger range = [ud integerForKey:SEARCHTAXI_RANGE];
    if (range == 0)
    {
        range = 5;
    }
    return range;
}


+ (NSData*)GetLoginData
{
    NSMutableData *loginData = [[NSMutableData alloc] init];
    NSString *udidInstead = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
    udidInstead = [udidInstead stringByPaddingToLength:40 withString:@"0" startingAtIndex:0];
    NSData *udidInsteadData = [udidInstead dataUsingEncoding: NSUTF8StringEncoding];
    NSData *versionData = [Common GetVersion];
    
    NSInteger bodyLength = versionData.length + udidInsteadData.length;
    NSData *messageHead =[self GetMessageHeadWhitPhoneNumber:[self UserPhoneNumber] andMessageID:MESSAGE_ID_LOGIN andMessageBodyLength:bodyLength];
    
    [loginData appendData:messageHead];
    [loginData appendData:udidInsteadData];
    [loginData appendData:versionData];
    
    NSData *sendData = [self PackageSendData:loginData];
    return sendData;
}


+ (NSData *)GetSearchTaxiDataWithLatitude:(double)latitude andLongitude:(double)longitude range:(Byte)range
{
    NSMutableData *searchTaxiData = [[NSMutableData alloc] init];
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    
    NSString *latitudeString = [[NSString stringWithFormat:@"%d",(int) (latitude * pow(10, 6))]
                                stringByPaddingTheLeftToLength:10 withString:@"0" startingAtIndex:0];
    NSString *longitudeString = [[NSString stringWithFormat:@"%d",(int) (longitude * pow(10, 6))]
                                 stringByPaddingTheLeftToLength:10 withString:@"0" startingAtIndex:0];
    
    [bodyData appendData:[longitudeString hexToBytes]];
    [bodyData appendData:[latitudeString hexToBytes]];
    [bodyData appendBytes:&range length:sizeof(range)];
    
    NSData *messageHead =[self GetMessageHeadWhitPhoneNumber:[self UserPhoneNumber] andMessageID:MESSAGE_ID_SEARCHTAXI andMessageBodyLength:bodyData.length];
    [searchTaxiData appendData:messageHead];
    [searchTaxiData appendData:bodyData];
    NSData *sendData = [self PackageSendData:searchTaxiData];    
    return sendData;
}

+ (NSData *)GetAllBusData
{
    NSData *messageHead = [self GetMessageHeadWhitPhoneNumber:[OperateAgreement UserPhoneNumber] andMessageID:MESSAGE_ID_GetAllBus andMessageBodyLength:0];
    NSData *sendData = [self PackageSendData:messageHead];
    return sendData;

}

+ (NSData *)GetUpdataReferrerData:(NSString *)name
{
    
    NSMutableData *searchTaxiData = [[NSMutableData alloc] init];
    
    
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
    NSData *bodyData = [name dataUsingEncoding:enc];
    
    NSData *messageHead =[self GetMessageHeadWhitPhoneNumber:[self UserPhoneNumber] andMessageID:MESSAGE_ID_UpdataReferrer andMessageBodyLength:bodyData.length];
    [searchTaxiData appendData:messageHead];
    [searchTaxiData appendData:bodyData];
    NSData *sendData = [self PackageSendData:searchTaxiData];
    return sendData;
}


+ (NSData*)GetSendTransactionData:(NSString*)driverPhoneNumber
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    //[dateFormatter setDateFormat:@"hh:mm:ss"]
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *datestring = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableData *transactionData = [[NSMutableData alloc] init];
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    
    [bodyData appendData:[datestring hexToBytes]];
    driverPhoneNumber = [driverPhoneNumber stringByPaddingTheLeftToLength:12 withString:@"0" startingAtIndex:0];

    [bodyData appendData:[driverPhoneNumber hexToBytes]];
    
      NSData *messageHead =[self GetMessageHeadWhitPhoneNumber:[self UserPhoneNumber] andMessageID:MESSAGE_ID_UPLoadTrade andMessageBodyLength:bodyData.length];
    
    [transactionData appendData:messageHead];
    [transactionData appendData:bodyData];
    NSData *sendData = [self PackageSendData:transactionData];
    

    return sendData;
}



/// Restore ReceData. 0x7d  0x02 -- 0x7e ；0x7d  0x01  --- 0x7d；
/// <returns>realData</returns>
+ (NSData *)RestoreReceData:(NSData *)receData
{
    NSMutableData *realData = [[NSMutableData alloc] init];
    
    
    NSUInteger len = [receData length];
    Byte *receDataByteArray = (Byte*)malloc(len);
    memcpy(receDataByteArray, [receData bytes], len);
    
    Byte helpByte_7d = 0x7d;
    Byte helpByte_7e = 0x7e;
    
    for (int i = 0; i < len; i++)
    {
        if (i != len - 1)
        {
            if (receDataByteArray[i] == 0x7d && receDataByteArray[i + 1] == 0x01)
            {
                [realData appendBytes:&helpByte_7d length:sizeof(Byte)];
                i++;
                continue;
            }
            if (receDataByteArray[i] == 0x7d && receDataByteArray[i + 1] == 0x02)
            {
                [realData appendBytes:&helpByte_7e length:sizeof(Byte)];
                i++;
                continue;
            }
        }
        [realData appendBytes:&receDataByteArray[i] length:sizeof(Byte)];
        
    }
    return realData;
}


+ (NSString *)GetMessageIdInMessageHead:(NSData *)realData
{
    NSString * messageID;
    NSData *messageIDData = [realData subdataWithRange:NSMakeRange(1, 2)];
    //[realData getBytes:&messageID range:NSMakeRange(1, 2)];
    messageID = [messageIDData hexRepresentationWithSpaces_AS:NO];
    return messageID;
}


+ (BOOL)JudgeisCompleteData:(NSData *)data
{
    NSUInteger len = [data length];
    Byte *realData = (Byte*)malloc(len);
    memcpy(realData, [data bytes], len);
    
    if (len < MESSAGE_HEAD_LENGTH || realData[0] != 0x7e || realData[len - 1] != 0x7e)
    {
        NSLog(@"JudgeisCompleteData --NO1");
        return NO;
    }

    int recedataLegth =  [self GetMessageLengthInMessageHead:data]; 
    if (recedataLegth != len - MESSAGE_HEAD_LENGTH)
    {
        NSLog(@"JudgeisCompleteData --NO2");
        return NO;
    }
    NSData *messageHeadAndBoyd = [data subdataWithRange:NSMakeRange(1, data.length-3)];
    Byte checkByte = [self GetCheckByte:messageHeadAndBoyd];
    if (checkByte != realData[len - 2])
    {
        NSLog(@"JudgeisCompleteData --NO3");
        return NO;
    }
    
    return true;
}

//<7e870116 00018602 78958800 00000000 00010000 00000079 22252222 00004999 10002780 3135305c 7e>
+ (ushort)GetMessageLengthInMessageHead:(NSData *)realData
{
    ushort messageLength;
    [realData getBytes:&messageLength range:NSMakeRange(3, 2)];
    NSString *messageLengthBinaryStr = [Common ShortToBinaryString:messageLength];
    messageLengthBinaryStr = [messageLengthBinaryStr substringFromIndex:7];
    
    messageLength = [Common BinaryStringToInt:messageLengthBinaryStr];
    
    return messageLength;
}


+ (UIImage *)GetTaxiImageWithAngle:(short)angle andTaxiState:(Byte)state
{
    NSString *imageName = [NSString stringWithFormat:@"0%d4.png",[self GetOritationByCarTravelingAngle:angle]];
    UIImage *image =[UIImage imageNamed:imageName];
    return image;

}

+ (UIImage *)GetBusImageWithAngle:(short)angle
{
    NSString *imageName = [NSString stringWithFormat:@"%d.png",[self GetOritationByCarTravelingAngle:angle]];
    UIImage *image =[UIImage imageNamed:imageName];
    return image;
}

+ (void)SaveCallTaxiRecordWhitDriverPhoneNumber:(NSString *)phoneNumber andLicenseplatenumber:(NSString *)licenseplatenumber
{
    NSDateFormatter *nsdf2=[[NSDateFormatter alloc] init];
    [nsdf2 setDateStyle:NSDateFormatterShortStyle];
    [nsdf2 setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *time=[nsdf2 stringFromDate:[NSDate date]];
    
    
    
    fileOperate *fileoperate=[[fileOperate alloc] init];
    NSString *filePath=[fileoperate getFilePath:@"CallTaxiRecord.csv"];

    NSString *result=[NSString stringWithFormat:@"%@,%@,%@",licenseplatenumber,phoneNumber,time];
    [fileoperate saveFile:filePath withAppendString:result];
}


+ (NSArray *)getCallTaxiRecord
{
    
    fileOperate *fileoperate=[[fileOperate alloc] init];
    NSString *recordString = [fileoperate loadFile:[fileoperate getFilePath: @"CallTaxiRecord.csv"]];
    
    NSArray *tempRecord=[recordString componentsSeparatedByString:@"\n"];

    NSMutableArray *arry = [[NSMutableArray alloc] init];
    for (NSString *str in tempRecord)
    {
        if (str.length > 0)
        {
            NSArray *tempCallTaxiRecord=[str componentsSeparatedByString:@","];
            
            if (tempCallTaxiRecord.count == 3)
            {
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                
                [dic setValue:tempCallTaxiRecord[0] forKey:Taxi_Record_TaxiNumber];
                [dic setValue:tempCallTaxiRecord[1] forKey:Taxi_Record_DriverPhoneNumber];
                [dic setValue:tempCallTaxiRecord[2] forKey:Taxi_Record_Time];

                [arry addObject:dic];
            }
      
        }
    }

    return arry;
}

#pragma mark Private


//通过角度具体数值，获取8个方向之一
+ (int) GetOritationByCarTravelingAngle:(Byte)CarTravelingAngle
{
    if (CarTravelingAngle>=0 && CarTravelingAngle<45)
        return 1;
    if (CarTravelingAngle>=45 && CarTravelingAngle<90)
        return 2;
    if (CarTravelingAngle>=90 && CarTravelingAngle<135)
        return 3;
    if (CarTravelingAngle>=135 && CarTravelingAngle<180)
        return 4;
    if (CarTravelingAngle>=180 && CarTravelingAngle<225)
        return 5;
    if (CarTravelingAngle>=225 && CarTravelingAngle<270)
        return 6;
    if (CarTravelingAngle>=270 && CarTravelingAngle<315)
        return 7;
    if (CarTravelingAngle>=315 && CarTravelingAngle<360)
        return 8;
    //    如果都没有，则返回一个9
    return 9;
}


/// Restore ReceData. 0x7e -- 0x7d  0x02；0x7d --- 0x7d  0x01；
+ (NSData *)TransferToSendData:(NSData *)messageHeadAndBodyData
{
    NSMutableData *sendData = [[NSMutableData alloc] init];
    
    NSUInteger len = [messageHeadAndBodyData length];
    Byte *realData = (Byte*)malloc(len);
    memcpy(realData, [messageHeadAndBodyData bytes], len);
    
    Byte helpByte_7d = 0x7d;
    Byte helpByte_02 = 0x02;
    Byte helpByte_01 = 0x01;
    
    for (int i = 0; i < len; i++)
    {
        if (realData[i] == 0x7e)
        {
            [sendData appendBytes:&helpByte_7d length:sizeof(Byte)];
            [sendData appendBytes:&helpByte_02 length:sizeof(Byte)];
        }
        else if (realData[i] == 0x7d)
        {
            [sendData appendBytes:&helpByte_7d length:sizeof(Byte)];
            [sendData appendBytes:&helpByte_01 length:sizeof(Byte)];
        }
        else
        {
            [sendData appendBytes:&realData[i] length:sizeof(Byte)];
            
        }
    }
    return sendData;
}


// according  a  full command  return CheckByte
+ (Byte)GetCheckByte:(NSData *)messageHeadAndBodyData
{
    Byte CheckByte = 0;
    for(int i = 0;i < messageHeadAndBodyData.length; i++)
    {
        Byte tempbyte;
        [messageHeadAndBodyData getBytes:&tempbyte range:NSMakeRange(i, 1)];
        CheckByte = CheckByte ^ tempbyte;
    }
    return CheckByte;
}




+ (NSData *)PackageSendData:(NSData *)messageHeadAndBodyData
{
    NSMutableData *realData = [[NSMutableData alloc] init];
    Byte helpByte = 0x7e;
    Byte checkByte = [self GetCheckByte:messageHeadAndBodyData];
    
    NSData *messageHeadAndBodyDataAfterTransfer = [self TransferToSendData:messageHeadAndBodyData];
    
    [realData appendBytes:&helpByte length:sizeof(helpByte)];
    [realData appendData:messageHeadAndBodyDataAfterTransfer];
    [realData appendBytes:&checkByte length:sizeof(checkByte)]; //check byte
    [realData appendBytes:&helpByte length:sizeof(helpByte)];
    
    //[realData replaceBytesInRange:NSMakeRange(realData.length-2, 1) withBytes:&checkByte];
    
    
    
    return realData;
}




+ (NSData *)GetMessageHeadWhitPhoneNumber:(NSString *)phoneNumber andMessageID:(NSString *)messageID andMessageBodyLength:(ushort)bodyLength
{
    
    NSMutableData *messageHead = [[NSMutableData alloc] init];
    NSData *messageIDData = [messageID hexToBytes];
    
    [messageHead appendData:messageIDData];
    ushort messageAttribute = bodyLength;
    
    [messageHead appendBytes:&messageAttribute length:sizeof(messageAttribute)];
    phoneNumber = [phoneNumber stringByPaddingTheLeftToLength:12 withString:@"0" startingAtIndex:0];
    [messageHead appendData:[phoneNumber hexToBytes]];
    
    ushort serialNo = 0;
    ushort packgeCounts = 0;
    ushort packageIndex = 0;
    [messageHead appendBytes:&serialNo length:sizeof(serialNo)];
    [messageHead appendBytes:&packgeCounts length:sizeof(packgeCounts)];
    [messageHead appendBytes:&packageIndex length:sizeof(packageIndex)];
    
    return messageHead;
}



@end
