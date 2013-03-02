//
//  OperateAgreement.h
//  CallTaxi
//
//  Created by Fan Lv on 13-2-11.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UDP_SEND_PORT            9588
#define UDP_TAXI_SERVER_PORT     8588
#define UDP_BUS_SERVER_PORT      28588

// MessageID Reverse
#define MESSAGE_ID_LOGIN                 @"0701" 
#define MESSAGE_ID_LOGIN_REPLY           @"8701"
#define MESSAGE_ID_SEARCHTAXI            @"0B05"
#define MESSAGE_ID_SEARCHTAXI_REPLY      @"8B05"
#define MESSAGE_ID_UPLoadTrade           @"0B02"
#define MESSAGE_ID_UPLoadTrade_REPLY     @"8B02"
#define MESSAGE_ID_GetAllBus             @"0001"
#define MESSAGE_ID_GetAllBus_REPLY       @"8001"
#define MESSAGE_ID_UpdataReferrer        @"0025"
#define MESSAGE_ID_UpdataReferrer_REPLY  @"8025"


//----------Config
#define TAXI_SERVER_HOST                 @"TAXI_SERVER_HOST"
#define USER_PHONENUMBER                 @"localphonenumber"
#define SEARCHTAXI_RANGE                 @"SEARCHTAXI_RANGE"
#define SERVER_CITY_NAME                 @"SERVER_CITY_NAME" 
#define USER_REFERRER                    @"USER_REFERRER"
#define SERVER_PHONENUMBER               @"SERVER_PHONENUMBER"




#define Taxi_Record_TaxiNumber           @"Taxi_Record_TaxiNumber"
#define Taxi_Record_DriverPhoneNumber    @"Taxi_Record_DriverPhoneNumber"
#define Taxi_Record_Time                 @"Taxi_Record_Time"

#define LAST_UESRLOCATION_LATITUDE       @"last_userlocation_latitude"
#define LAST_UESRLOCATION_LONGITUDE      @"last_userlocation_longitude"



#define COMPANY_WEBSITE                  @"http://www.cityofcar.com"


#define MESSAGE_HEAD_LENGTH           19      //Message Head Length(+First and Last identification+Check bit)  
#define MESSAGE_BODY_START_INDEX      17


@interface OperateAgreement : NSObject


+ (BOOL)JudgeisCompleteData:(NSData *)data;

+ (NSString *)GetMessageIdInMessageHead:(NSData *)realData;

+ (ushort)GetMessageLengthInMessageHead:(NSData *)realData;

+ (ushort)GetPackageCountInMessageHead:(NSData *)realData;

+ (ushort)GetPackageIndexInMessageHead:(NSData *)realData;

+ (NSData *)GetLoginData;

+ (NSData *)GetSearchTaxiDataWithLatitude:(double)latitude andLongitude:(double)longitude range:(Byte)range;

+ (NSData *)GetAllBusData;

+ (NSData *)GetUpdataReferrerData:(NSString *)name;

+ (NSData *)RestoreReceData:(NSData *)receData;

+ (void)SetTaxiServerHost:(NSString *)taxiServerHost ;

+ (NSString *)TaxiServerHost;

+ (NSString *)BusServerHost;


+ (void)SetUserPhoneNumber:(NSString *)phoneNumber ;

+ (NSString *)UserPhoneNumber;


+ (void)SetServerCityName:(NSString *)cityName ;

+ (NSString *)ServerCityName;

+ (NSArray *)GetServerNameList;

+ (void)SetReferrer:(NSString *)peopleName ;

+ (NSString *)Referrer;

+ (void)SetServerPhoneNumber:(NSString *)phoneNumber ;

+ (NSString *)ServerPhoneNumber;


+ (void)SetRange:(NSInteger)range;

+ (NSInteger)Range;

+ (UIImage *)GetTaxiImageWithAngle:(short)angle andTaxiState:(Byte)state;

+ (UIImage *)GetBusImageWithAngle:(short)angle;



+ (NSData*)GetSendTransactionData:(NSString*)driverPhoneNumber;


+ (void)SaveCallTaxiRecordWhitDriverPhoneNumber:(NSString *)phoneNumber andLicenseplatenumber:(NSString *)licenseplatenumber;

+ (NSArray *)getCallTaxiRecord;




@end
