//
//  SearchTaxiViewController.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-5.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "SearchTaxiViewController.h"
#import "AsyncUdpSocket.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import "Common.h"
#import "SGInfoAlert.h"
#import "OperateAgreement.h"
#import "TaxiInfo.h"
#import "NSData+Hex.h"
#import "SVProgressHUD.h"
#import "TaxiListModeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>



@interface SearchTaxiViewController ()<MKMapViewDelegate,CLLocationManagerDelegate,UIGestureRecognizerDelegate,AVAudioPlayerDelegate>
{
    TaxiInfo *didSelectTaxiInfo;
    BOOL getCurrentPostioning;
    BOOL isLogining;
    BOOL isSearching;
    BOOL isStartReceTaxiInfo;
    BOOL isSearched;
    BOOL isGetUserLocation;
    BOOL isCalledTaxiPhone;
    int trySearchTaxiCount;
    double clickCallphoneNumberBtnTimeMillis;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIButton *currentPostionButton;
@property (strong,nonatomic) AsyncUdpSocket *socket;
@property (strong,nonatomic) UIActivityIndicatorView *spinner;
@property (strong,nonatomic) UIAlertView *phoneNumberAlertView;
@property (strong,nonatomic) NSArray *taxiList;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) NSTimer *searchTaxiTimer;




@end

@implementation SearchTaxiViewController

@synthesize currentPostionButton = _currentPostionButton;
@synthesize mapView = _mapView;
@synthesize spinner = _spinner;
@synthesize socket = _socket;
@synthesize phoneNumberAlertView = _phoneNumberAlertView;
@synthesize taxiList = _taxiList;
@synthesize audioPlayer = _audioPlayer;
@synthesize locationManager = _locationManager;
@synthesize searchTaxiTimer = _searchTaxiTimer;

#pragma mark - property



const int stPhoneNumberAlertViewTag = 100;
const int isCalledTaxiPhoneTag = 101;
const int phoneNumberTextFieldTag = 102;

- (NSTimer *)searchTaxiTimer
{
    if (_searchTaxiTimer == nil)
    {
        _searchTaxiTimer =[NSTimer scheduledTimerWithTimeInterval:5
                                                           target:self
                                                         selector:@selector(searchTaxiThread:)
                                                         userInfo:nil
                                                          repeats:YES];
    }
    return _searchTaxiTimer;
}

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 1000;
    }
    return _locationManager;
}

- (AsyncUdpSocket *)socket
{
    if (_socket == nil)
    {
        _socket = [[AsyncUdpSocket alloc] initIPv4];
        _socket.delegate = self;
        _socket.maxReceiveBufferSize = 5000;
        //绑定端口
        //NSError *error = nil;
        // [self.socket bindToPort:UDP_SEND_PORT error:&error];
        [self.socket receiveWithTimeout:-1 tag:0];
    }
    return _socket;
}


- (UIActivityIndicatorView *)spinner
{
    if (_spinner == nil)
    {
        _spinner= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _spinner;
}


- (UIAlertView *)phoneNumberAlertView
{
    if (_phoneNumberAlertView == nil)
    {
        _phoneNumberAlertView = [[UIAlertView alloc] initWithTitle:@"请输入本机号码" message:nil delegate:self
                                                 cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        _phoneNumberAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        _phoneNumberAlertView.tag = stPhoneNumberAlertViewTag;
        UITextField *textField = [_phoneNumberAlertView textFieldAtIndex:0];
        textField.tag = phoneNumberTextFieldTag;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        [_phoneNumberAlertView addSubview:textField];
    }
    return  _phoneNumberAlertView;
}
#pragma mark - View Lifecycle


- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    
    [self InitializationConfig];
    isGetUserLocation = NO;
    
    //定时器
    NSTimer *showTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                          target:self
                                                        selector:@selector(loginThread:)
                                                        userInfo:nil
                                                         repeats:YES];
    [showTimer fire];
    
    //  check LocationManager
    if ([CLLocationManager locationServicesEnabled])
    {
        [self.spinner startAnimating];
        [self.locationManager startUpdatingLocation];
        
        getCurrentPostioning = YES;
    }
    else
    {
        [self.spinner stopAnimating];
        [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: NO];
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
        [self.currentPostionButton setImage:buttonArrow forState:UIControlStateNormal];
    }
    
}


- (void)handleWillResignActive
{
    
    double currentTimeMillis = [[NSDate date] timeIntervalSince1970]; //* 1000;
    double dvalue = currentTimeMillis - clickCallphoneNumberBtnTimeMillis;
    NSLog(@"dvalue --111111--- : %f", dvalue);
    //占时这样判断。
    if (dvalue > 1 && dvalue < 10)
    {
        isCalledTaxiPhone = YES;
    }
}

- (void)handleDidBecomeActive
{
    
    if (isCalledTaxiPhone)
    {
        isCalledTaxiPhone = NO;
        NSString *info = [NSString stringWithFormat:@"是否招车成功？"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:info
                                                           delegate:self cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
        
        alertView.tag = isCalledTaxiPhoneTag;
        [alertView show];
    }
}



- (void)viewDidUnload
{
    self.socket = nil;
    [self setMapView:nil];
    [self setCurrentPostionButton:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleWillResignActive)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleDidBecomeActive)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [self resignFirstResponder];
    [super viewDidDisappear:animated];
}


-(void)loginThread:(NSTimer *)theTimer
{
    if (!isLogining)
    {
        //--------------------------Login
        [self sendData:[OperateAgreement GetLoginData]];
    }
    else
    {
        [theTimer invalidate];
    }
}

#pragma mark Segue to ListMode


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showListMode"])
    {
        clickCallphoneNumberBtnTimeMillis = 0;
        TaxiListModeViewController *taxiListModeController = [segue destinationViewController];
        taxiListModeController.taxiList = self.taxiList;
        if (isSearched)
        {
            taxiListModeController.isSearch = YES;
        }
        else
        {
            taxiListModeController.isSearch = NO;
        }
        
    }
}

#pragma mark - UDP Delegate

- (void)sendData:(NSData * )data
{
    //    if (![Common isExistenceNetwork])
    //    {
    //        [SGInfoAlert showInfo: @"系统未检测到网络连接,请开启WiFi或GPRS"
    //                      bgColor:[[UIColor blackColor] CGColor]
    //                       inView:self.view vertical:0.6];
    //
    //        //--------stop SearchTaxi timer
    //        trySearchTaxiCount = 100;
    //        [SVProgressHUD dismiss];
    //        return;
    //    }
    if ([OperateAgreement UserPhoneNumber].length == 0)
    {
        return;
    }
    NSLog(@"sendto  %@",[OperateAgreement TaxiServerHost]);
    [self.socket sendData:data toHost:[OperateAgreement TaxiServerHost] port:UDP_TAXI_SERVER_PORT  withTimeout:1 tag:0];
    
}

//UDP接收消息
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    
    
    //---------Log
    NSString *info = [NSString stringWithFormat:@"host: %@,port : %hu",host,port];
    NSLog(@"%@",info);
//    [SGInfoAlert showInfo:info
//                  bgColor:[[UIColor darkGrayColor] CGColor]
//                   inView:self.view
//                 vertical:0.6];
    //启动监听下一条消息
    [self.socket receiveWithTimeout:-1 tag:0];
    
    BOOL isMessageStart = NO;
    
    
    NSMutableData *receData = [[NSMutableData alloc] init];
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < data.length; i++)
    {
        Byte tmp = -1;
        [data getBytes:&tmp range:NSMakeRange(i, 1)];
        if (tmp == 0x7e)
        {
            isMessageStart = !isMessageStart;
        }
        if (isMessageStart)
        {
            [receData appendBytes:&tmp length:sizeof(Byte)];
        }
        if (isMessageStart == NO && tmp == 0x7e)
        {
            [receData appendBytes:&tmp length:sizeof(Byte)];
            NSData *oneMessage = [receData copy];
            receData.length = 0 ;
            NSData *realOneMessage =[OperateAgreement RestoreReceData:oneMessage];
            [dataArray addObject:realOneMessage];
            
            
        }
    }
    
    [self analysisMessage:dataArray];
    
    
    return YES;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"Message not received for error: %@", error);
    self.socket = nil;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"Message not send for error: %@",error);
    self.socket = nil;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"Message send success!");
}

- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock
{
    self.socket = nil;
    NSLog(@"socket closed!");
}

#pragma mark Data Handling

- (void)analysisMessage:(NSArray *)dataArray
{
    NSData *realData = [dataArray objectAtIndex:0];
    if (![OperateAgreement JudgeisCompleteData:realData])
    {
        return;
    }
    NSString *messageID = [OperateAgreement GetMessageIdInMessageHead:realData];
    
    if ([messageID isEqual: MESSAGE_ID_LOGIN_REPLY])
    {
        [self loginMessageHandling:dataArray];
    }
    else if([messageID isEqualToString:MESSAGE_ID_SEARCHTAXI_REPLY])
    {
        [self searchTaxiMeaageHandling:dataArray];
    }
    else if([messageID isEqualToString:MESSAGE_ID_UPLoadTrade_REPLY])
    {
        NSLog(@"MESSAGE_ID_UPLoadTrade_REPLY");
    }
}

- (void)loginMessageHandling:(NSArray *)dataArray
{
    
    NSData *realData = [dataArray objectAtIndex:0];
    
    NSUInteger len = [realData length];
    Byte *realDataByteArray = (Byte*)malloc(len);
    memcpy(realDataByteArray, [realData bytes], len);
    
    
    NSInteger bodylength = [OperateAgreement GetMessageLengthInMessageHead:realData];
    
    if (bodylength == 1)
    {
        Byte result = -1;
        [realData getBytes:&result range:NSMakeRange(MESSAGE_BODY_START_INDEX, 1)];
        if (result == 0)
        {
            [SGInfoAlert showInfo:@"登录失败"
                          bgColor:[[UIColor darkGrayColor] CGColor]
                           inView:self.view
                         vertical:0.8];
        }
        else if(result == 1)
        {
            [SGInfoAlert showInfo:@"登录失败。你的电话号码已经已经被加入黑名单。"
                          bgColor:[[UIColor darkGrayColor] CGColor]
                           inView:self.view
                         vertical:0.8];
        }
    }
    else
    {
        NSString *serverIp = [NSString stringWithFormat:@"%d.%d.%d.%d",
                              realDataByteArray[MESSAGE_BODY_START_INDEX+1],realDataByteArray[MESSAGE_BODY_START_INDEX+2],
                              realDataByteArray[MESSAGE_BODY_START_INDEX+3],realDataByteArray[MESSAGE_BODY_START_INDEX+4]];
        if ([serverIp isEqualToString:@"0.0.0.0"])
        {
            isLogining = YES;
            [SGInfoAlert showInfo:@"登录成功"
                          bgColor:[[UIColor darkGrayColor] CGColor]
                           inView:self.view
                         vertical:0.8];
            
            
            NSData *ServerPhoneNumberData = [realData subdataWithRange:NSMakeRange(MESSAGE_BODY_START_INDEX+5, 6)];
            NSString *serverPhoneNumber = [[ServerPhoneNumberData hexRepresentationWithSpaces_AS:NO] substringFromIndex:1];
            [OperateAgreement SetServerPhoneNumber:serverPhoneNumber];
        }
        else
        {
            [OperateAgreement SetTaxiServerHost:serverIp];
        }
        
        
    }
}

short receTaxiInfoCurrentPacIndex = -1;
- (void)searchTaxiMeaageHandling:(NSArray *)dataArray
{
    [SVProgressHUD dismiss];
    isSearched = YES;
    isStartReceTaxiInfo = YES;
    if (isSearching == NO)
        return;
    
    NSMutableArray *taxiListTmp = [[NSMutableArray alloc] initWithArray:self.taxiList];
    for (NSData *realData in dataArray)
    {
        NSUInteger len = [realData length];
        Byte *realDataByteArray = (Byte*)malloc(len);
        memcpy(realDataByteArray, [realData bytes], len);
        
        
        
        ushort packageIndex =[OperateAgreement GetPackageIndexInMessageHead:realData];
        ushort packageCount =[OperateAgreement GetPackageCountInMessageHead:realData];
        
        if (receTaxiInfoCurrentPacIndex >= packageIndex)
            return;
        receTaxiInfoCurrentPacIndex = packageIndex;
        NSLog(@"%d",packageIndex);
        NSLog(@"%d",packageCount);
        
        NSData *taxiCountData = [Common reversedData:[realData subdataWithRange:NSMakeRange(MESSAGE_BODY_START_INDEX, 2)]];
        ushort taxiCount =  *(const UInt16 *)[taxiCountData bytes];
        
        for (int i = 0; i < taxiCount; i++)
        {
            TaxiInfo *taxiInfo = [[TaxiInfo alloc] init];
            NSInteger taxiInfoStartIndex = MESSAGE_BODY_START_INDEX + 2 + (i*45);
            
            taxiInfo.longitude = [[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex, 5)]
                                   hexRepresentationWithSpaces_AS:NO] doubleValue] / pow(10, 6);
            
            taxiInfo.latitude = [[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex+5, 5)]
                                  hexRepresentationWithSpaces_AS:NO] doubleValue] / pow(10, 6);
            
            taxiInfo.ipAddress = [NSString stringWithFormat:@"%d.%d.%d.%d",
                                  realDataByteArray[taxiInfoStartIndex+10],realDataByteArray[taxiInfoStartIndex+11],
                                  realDataByteArray[taxiInfoStartIndex+12],realDataByteArray[taxiInfoStartIndex+13]];
            //29.705172,116.005516
            taxiInfo.taxiState = realDataByteArray[taxiInfoStartIndex+14];
            
            taxiInfo.phoneNumber = [[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex +15,6)] hexRepresentationWithSpaces_AS:NO] substringFromIndex:1];
            
            NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
            
            taxiInfo.licenseplatenumber = [[NSString alloc] initWithData:[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex + 21, 8)] encoding:enc];
            
            taxiInfo.taxiType = [[NSString alloc] initWithData:[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex + 29, 12)] encoding:enc];
            
            taxiInfo.star = realDataByteArray[taxiInfoStartIndex + 41];
            
            taxiInfo.angle = *(const UInt16 *)[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex + 42, 2)] bytes];
            
            taxiInfo.speed = realDataByteArray[taxiInfoStartIndex + 44];
            
            //29.705172,116.005516
            double userLatitude = self.mapView.userLocation.coordinate.latitude;
            double userLongitude = self.mapView.userLocation.coordinate.longitude;
            
            
            if (userLongitude == 0 || userLatitude == 0
                || self.mapView.userLocation.location.verticalAccuracy > 300
                || self.mapView.userLocation.location.horizontalAccuracy > 300
                )
            {
                taxiInfo.distanceFromUser = 0;
            }
            else
            {
                CLLocation *cl1  =[[ CLLocation alloc] initWithLatitude:taxiInfo.latitude longitude:taxiInfo.longitude];
                CLLocation *cl2  =[[ CLLocation alloc] initWithLatitude:userLatitude longitude:userLongitude];
                CLLocationDistance distance = [cl1 distanceFromLocation:cl2];
                taxiInfo.distanceFromUser = distance;
            }
            
            [taxiListTmp addObject:taxiInfo];
            
        }
        self.taxiList = taxiListTmp;
        
        
        [self.mapView addAnnotations:self.taxiList];
        
        
        if (packageIndex == packageCount )
        {
            
            isSearching = NO;
            
            [self.searchTaxiTimer invalidate];
            self.searchTaxiTimer = nil;
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
            [taxiListTmp sortUsingDescriptors:sortDescriptors];
            [self showTaxionMapView:taxiListTmp Count:5];
            NSString *info = [[NSString alloc] initWithFormat:@"搜索到%d辆出租车！(范围:%d公里)",self.taxiList.count,[OperateAgreement Range]];
            
            [SGInfoAlert showInfo:info bgColor:[[UIColor darkGrayColor] CGColor]
                           inView:self.view vertical:0.7];
        }
        
    }
    
    
    
}



-(void)showTaxionMapView:(NSMutableArray *) array Count:(int) showcount;
{
    if (array.count == 0) return;
    if (array.count < showcount)
    {
        showcount = array.count;
    }
    MKMapRect zoomRect = MKMapRectNull;
    for (int i = 0;  i< showcount; i++)
    {
        TaxiInfo *taxiInfo = [self.taxiList objectAtIndex:i];
        MKMapPoint annotationPoint = MKMapPointForCoordinate(taxiInfo.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
    
    
    
}



#pragma mark - SearchTaxi



- (IBAction)searchTaxiClick:(id)sender
{
    [self searchTaxi];
}


- (void)searchTaxi
{
    if (isSearching)
    {
        [SGInfoAlert showInfo:@"请稍后在搜索。。。。" bgColor:[[UIColor darkGrayColor] CGColor]
                       inView:self.view vertical:0.6];
        return;
    }
    isSearching = YES;
    isStartReceTaxiInfo = NO;
    trySearchTaxiCount = 1;
    receTaxiInfoCurrentPacIndex = -1;
    
    
    [self.mapView removeAnnotations:self.taxiList];
    self.taxiList = nil;
    
    [SVProgressHUD showWithStatus:@"正在搜索附近出租车..."];
    self.searchTaxiTimer = nil;
    [self.searchTaxiTimer fire];
}

- (void)searchTaxiThread:(NSTimer *)theTimer
{
    if (trySearchTaxiCount > 2)
    {
        if (isSearching)
        {
            [SVProgressHUD dismissWithError:@"搜车请求超时..." afterDelay:3];
        }
        isSearching = NO;
    }
    
    if (isSearching)
    {
        if (isStartReceTaxiInfo == NO)
        {
            //--------------------------Login
            [self sendData:[OperateAgreement GetSearchTaxiDataWithLatitude:self.mapView.centerCoordinate.latitude
                                                              andLongitude:self.mapView.centerCoordinate.longitude
                                                                     range:[OperateAgreement Range]]];
        }
    }
    else
    {
        NSLog(@"invalidate");
        [theTimer invalidate];
        theTimer = nil;
    }
    trySearchTaxiCount ++;
}



#pragma mark - Initialization MapView、CurrentPostionButton

- (void)InitializationConfig
{
    
    // Initialization MapView、CurrentPostionButton
    [self InitializationMapView];
    [self InitializationCurrentPostionButton];
    
    clickCallphoneNumberBtnTimeMillis = 0;
    NSLog(@"%@",[OperateAgreement UserPhoneNumber]);
    NSLog(@"%@",[OperateAgreement TaxiServerHost]);
    
    if ([OperateAgreement UserPhoneNumber].length == 0)
    {
        [self.phoneNumberAlertView show];
    }
    
    
}

#pragma mark  AlertView


- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == stPhoneNumberAlertViewTag && buttonIndex == 0)
    {
        // ok button
        UITextField *textField = (UITextField *)[actionSheet viewWithTag:phoneNumberTextFieldTag];
        NSString *phoneNumber = textField.text;
        NSLog(@"%@",phoneNumber);
        if ([Common isMobileNumber:phoneNumber])
        {
            [OperateAgreement SetUserPhoneNumber:textField.text];
        }
        else
        {
            [SGInfoAlert showInfo:@"手机号码格式有误，请重新输入。"
                          bgColor:[[UIColor darkGrayColor] CGColor]
                           inView:self.view
                         vertical:0.476];
            self.phoneNumberAlertView = nil;
            [self.phoneNumberAlertView show];
        }
    }
    
    if (actionSheet.tag == isCalledTaxiPhoneTag && buttonIndex == 1)
    {
        if (didSelectTaxiInfo != nil)
        {
            NSData *sendData = [OperateAgreement GetSendTransactionData:didSelectTaxiInfo.phoneNumber];
            [self sendData:sendData];
            [OperateAgreement SaveCallTaxiRecordWhitDriverPhoneNumber:didSelectTaxiInfo.phoneNumber
                                                andLicenseplatenumber:didSelectTaxiInfo.licenseplatenumber];
        }
        
    }
    
    
}







- (void)InitializationMapView
{
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    self.mapView.userLocation.title = @"我的位置";
    
    //--add UIPanGestureRecognizer
    UIPanGestureRecognizer* panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    [panRec setDelegate:self];
    [self.mapView addGestureRecognizer:panRec];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    double longitude = [[ud objectForKey:LAST_UESRLOCATION_LONGITUDE] doubleValue];
    double latitude = [[ud objectForKey:LAST_UESRLOCATION_LATITUDE] doubleValue];
    if (longitude == 0 || latitude == 0)
    {
        
        longitude = 116.023795;
        latitude = 29.726823;
    }
    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude,longitude);
    float zoomLevel = 0.05;
    MKCoordinateRegion region = MKCoordinateRegionMake(coords, MKCoordinateSpanMake(zoomLevel, zoomLevel));
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}



- (void)InitializationCurrentPostionButton
{
    
    //Configure the button
    self.currentPostionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.currentPostionButton addTarget:self action:@selector(showUeserLocationOnMapView:) forControlEvents:UIControlEventTouchUpInside];
    //Add state images
    [self.currentPostionButton setBackgroundImage:[Common currentPostionBtnImgGreyButtonHighlight] forState:UIControlStateNormal];
    [self.currentPostionButton setBackgroundImage:[Common currentPostionBtnImgGreyButton] forState:UIControlStateHighlighted];
    [self.currentPostionButton setImage:[Common currentPostionBtnImgTransport] forState:UIControlStateNormal];
    
    [self.currentPostionButton.imageView addSubview:self.spinner];
    
    //[self.spinner startAnimating];
    //Position and Shadow
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.currentPostionButton.frame = CGRectMake(5,screenBounds.size.height-150,36,36);
    self.currentPostionButton.layer.cornerRadius = 8.0f;
    self.currentPostionButton.layer.masksToBounds = NO;
    self.currentPostionButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.currentPostionButton.layer.shadowOpacity = 0.8;
    self.currentPostionButton.layer.shadowRadius = 1;
    self.currentPostionButton.layer.shadowOffset = CGSizeMake(0, 1.0f);
    
    [self.mapView addSubview:self.currentPostionButton];
    
}

- (IBAction) showUeserLocationOnMapView:(id)sender
{
    if (self.spinner.isAnimating)
    {
        return;
    }
    
    
    if (![CLLocationManager locationServicesEnabled])
    {
        [SGInfoAlert showInfo: @"请先在设置里面打开您的定位服务"
                      bgColor:[[UIColor blackColor] CGColor]
                       inView:self.view vertical:0.6];
        return;
    }
    
    if (isGetUserLocation == NO)
    {
        getCurrentPostioning = YES;
        [self.currentPostionButton setImage:[Common currentPostionBtnImgTransport] forState:UIControlStateNormal];
        [self.spinner startAnimating];
        return;
    }
    
    if(self.mapView.userTrackingMode == MKUserTrackingModeNone)
    {
        [self.mapView setUserTrackingMode: MKUserTrackingModeFollow animated: YES];
        [self.currentPostionButton setImage:[Common currentPostionBtnImgLocationBlue] forState:UIControlStateNormal];
    }
    else if(self.mapView.userTrackingMode == MKUserTrackingModeFollow)
    {
        [self.mapView setUserTrackingMode: MKUserTrackingModeFollowWithHeading animated: YES];
        [self.currentPostionButton setImage:[Common currentPostionBtnImgLocationHeadingBlue] forState:UIControlStateNormal];
    }
    else if(self.mapView.userTrackingMode == MKUserTrackingModeFollowWithHeading)
    {
        [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: YES];
        [self.currentPostionButton setImage:[Common currentPostionBtnImgLocationGrey] forState:UIControlStateNormal];
    }
    
}

#pragma mark - CLLocationManagerDelegate Methods


//-----在安徽、四川、等地方显示的公司名字不一样。
BOOL isTestCity = NO;

//获取位置信息
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (placemarks.count > 0)
         {
             CLPlacemark * localCity = [placemarks objectAtIndex:0];
             //NSLog(@"%@",localCity.administrativeArea);
             BOOL found = NO;
             NSArray *arrayOfStrings = [[NSArray alloc] initWithObjects:@"Anhui",@"安徽",@"Gansu",@"甘肃",
                                        @"Chongqing",@"重庆", @"Sichuan",@"四川",nil];
             for (NSString *s in arrayOfStrings)
             {
                 if ([localCity.administrativeArea rangeOfString:s].location != NSNotFound)
                 {
                     found = YES;
                     break;
                 }
             }
             isTestCity = found;
             
             //---用户第一次登录的时候默认值是九江市，如果获取到位置信息后，会自动切换到改城市。
             if ([localCity.locality isEqualToString:@"武汉市"] || [localCity.locality isEqualToString:@"Wuhan"])
             {
                 [OperateAgreement SetServerCityName:@"武汉市"];
             }
             
         }
         
       
     }];
    
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - MKMapView Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    
    if ([annotation isKindOfClass:[TaxiInfo class]])
    {
        TaxiInfo *taxiInfo = annotation;
        MKAnnotationView *aView=[mapView dequeueReusableAnnotationViewWithIdentifier:@"taxi"];
        if (!aView)
        {
            aView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"taxi"];
            aView.canShowCallout = YES;
            
            aView.image = [OperateAgreement GetTaxiImageWithAngle:taxiInfo.angle andTaxiState:taxiInfo.taxiState];
            aView.frame = CGRectMake(0, 0, 30, 30);
            aView.calloutOffset = CGPointMake(2,0);
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
            rightButton.frame = CGRectMake(0, 0, 30, 30);
            [rightButton setImage:[Common callPhoneNumberImage] forState:UIControlStateNormal];
            [rightButton addTarget:self
                            action:@selector(CallTaxiPhoneNumber:)
                  forControlEvents:UIControlEventTouchUpInside];
            aView.rightCalloutAccessoryView = rightButton;
        }
        return aView;
    }
    
    return nil;
    
}

- (void)CallTaxiPhoneNumber:(id)sender
{
    UIButton *btn = (UIButton *) sender;
    MKAnnotationView *av = (MKAnnotationView *)[[btn superview] superview];
    TaxiInfo *taxiInfo = av.annotation;
    
    
    if (taxiInfo)
    {
        [Common makeCall:taxiInfo.phoneNumber];
        clickCallphoneNumberBtnTimeMillis = [[NSDate date] timeIntervalSince1970] ;
    }
}





- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    didSelectTaxiInfo = view.annotation;
}


- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if(self.mapView.userTrackingMode == MKUserTrackingModeNone)
    {
        [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: YES];
        [self.currentPostionButton setImage:[Common currentPostionBtnImgLocationGrey] forState:UIControlStateNormal];
    }
    
}


- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    [self.spinner stopAnimating];
    [SGInfoAlert showInfo: @"didFailToLocateUserWithError"
                  bgColor:[[UIColor blackColor] CGColor]
                   inView:self.view vertical:0.6];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [self.spinner stopAnimating];
    if (isGetUserLocation == NO)
    {
        isGetUserLocation = YES;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:[NSString stringWithFormat:@"%f",userLocation.coordinate.latitude] forKey:LAST_UESRLOCATION_LATITUDE];
        [ud setObject:[NSString stringWithFormat:@"%f",userLocation.coordinate.longitude] forKey:LAST_UESRLOCATION_LONGITUDE];
        [ud synchronize];

    }
    if(getCurrentPostioning)
    {
        getCurrentPostioning = FALSE;
        [self.mapView setUserTrackingMode: MKUserTrackingModeFollow animated: YES];
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationBlue.png"];
        [self.currentPostionButton setImage:buttonArrow forState:UIControlStateNormal];
    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)didDragMap:(UIGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        if (getCurrentPostioning)
        {
            [self.spinner stopAnimating];
            getCurrentPostioning = FALSE;
            [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: NO];
            UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
            [self.currentPostionButton setImage:buttonArrow forState:UIControlStateNormal];
        }
    }
}




#pragma mark - 摇一摇
static SystemSoundID soundIDTest = 0;
- (void)initshake
{
    UInt32 sessionCategory = kAudioSessionCategory_AmbientSound;    // 1
    
    AudioSessionSetProperty (
                             kAudioSessionProperty_AudioCategory,                        // 2
                             sizeof (sessionCategory),                                   // 3
                             &sessionCategory                                            // 4
                             );
    
    
    
    NSString * path = [[NSBundle mainBundle] pathForResource:@"on" ofType:@"m4r"];
    
    if (path) { // test for path, to guard against crashes
        
        UInt32 sessionCategory = kAudioSessionCategory_AmbientSound;    // 1
        
        AudioSessionSetProperty (
                                 kAudioSessionProperty_AudioCategory,                        // 2
                                 sizeof (sessionCategory),                                   // 3
                                 &sessionCategory                                            // 4
                                 );
        AudioServicesCreateSystemSoundID( (__bridge CFURLRef)[NSURL fileURLWithPath:path], &soundIDTest );
    }
    
}


- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void) motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
 
            NSLog(@"Shake..........");
            
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            [self PlayShakeMusic];
            [self searchTaxi];
        
    }
}

//- (void)


#pragma mark 实现摇一摇播放声音方法
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag{
    
    NSLog(@"Finished playing the song");
    
    /* The [flag] parameter tells us if the playback was successfully
     finished or not */
    
    if ([player isEqual:self.audioPlayer]){
        self.audioPlayer = nil;
    }
    
}

//播放摇一摇的声音
-(void) PlayShakeMusic
{
    
    
    NSString *soundPath=[[NSBundle mainBundle] pathForResource:@"on" ofType:@"m4r"];
    NSURL *soundUrl=[[NSURL alloc] initFileURLWithPath:soundPath];
    self.audioPlayer=[[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    
    //self.audioPlayer = [[AVAudioPlayer alloc] initWithData:fileData error:&error];
    if (self.audioPlayer != nil)
    {
        /* Set the delegate and start playing */
        self.audioPlayer.delegate = self;
        if ([self.audioPlayer prepareToPlay] &&
            [self.audioPlayer play])
        {
            /* Successfully started playing */
        }
        else {
            /* Failed to play */
        }
    }
}



@end
