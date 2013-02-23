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
    BOOL getCurrentPostioning;
    BOOL isLogining;
    BOOL isSearching;
    BOOL isSearched;
    BOOL isGetUserLocation;
    int trySearchTaxiCount;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIButton *currentPostionButton;
@property (strong,nonatomic) CLLocationManager *locationManager;
@property (strong,nonatomic) AsyncUdpSocket *socket;
@property (strong,nonatomic) UIActivityIndicatorView *spinner;
@property (strong,nonatomic) UIAlertView *phoneNumberAlertView;
@property (strong,nonatomic) NSArray *taxiList;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;




@end

@implementation SearchTaxiViewController

@synthesize currentPostionButton = _currentPostionButton;
@synthesize mapView = _mapView;
@synthesize locationManager = _locationManager;
@synthesize spinner = _spinner;
@synthesize socket = _socket;
@synthesize phoneNumberAlertView = _phoneNumberAlertView;
@synthesize taxiList = _taxiList;
@synthesize audioPlayer = _audioPlayer;

#pragma mark  property




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

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];//创建位置管理器
        _locationManager.delegate = self;//设置代理
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;//指定需要的精度级别
        _locationManager.distanceFilter =  1000;//设置距离筛选器
    }
    return _locationManager;
}

- (UIAlertView *)phoneNumberAlertView
{
    if (_phoneNumberAlertView == nil)
    {
        _phoneNumberAlertView = [[UIAlertView alloc] initWithTitle:@"请输入本机号码" message:nil delegate:self
                                                 cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        _phoneNumberAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        _phoneNumberAlertView.tag = 100;
        UITextField *textField = [_phoneNumberAlertView textFieldAtIndex:0];
        textField.tag = 101;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        [_phoneNumberAlertView addSubview:textField];
    }
    return  _phoneNumberAlertView;
}

#pragma mark View Lifecycle


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
        [self.locationManager startUpdatingLocation];//启动位置管理器
        [self.spinner startAnimating];
        getCurrentPostioning = YES;

    }
    else
    {
        //        UIAlertView * alertA= [[UIAlertView alloc] initWithTitle:@"" message:@"请在设置里面打开您的定位服务"
        //                                                        delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        //        [alertA show];
        
        [self.spinner stopAnimating];
        [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: NO];
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
        [self.currentPostionButton setImage:buttonArrow forState:UIControlStateNormal];
    }
    
}


- (void)viewDidUnload {
    self.socket = nil;
    [self setMapView:nil];
    [self setCurrentPostionButton:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
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

#pragma mark segue to ListMode


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showListMode"])
    {
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

#pragma mark UDP Delegate

- (void)sendData:(NSData * )data
{
    if (![Common isExistenceNetwork])
    {
        [SGInfoAlert showInfo: @"系统未检测到网络连接,请开启WiFi或GPRS"
                      bgColor:[[UIColor blackColor] CGColor]
                       inView:self.view vertical:0.6];
        
        //--------stop SearchTaxi timer
        trySearchTaxiCount = 100;
        [SVProgressHUD dismiss];
        return;
    }
    if ([OperateAgreement UserPhoneNumber].length == 0)
    {
        return;
    }
    if (self.socket != nil)
    {
        [self.socket sendData:data toHost:[OperateAgreement TaxiServerHost] port:UDP_TAXI_SERVER_PORT  withTimeout:1 tag:0];
    }
    //sleep(5);
    
}

//UDP接收消息
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    //---------Log
    NSString *info = [NSString stringWithFormat:@"host: %@,port : %hu",host,port];
    NSLog(@"%@",info);
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

- (void)searchTaxiMeaageHandling:(NSArray *)dataArray
{
    [SVProgressHUD dismiss];
    isSearched = YES;
    if (isSearching == NO) return;
    isSearching = NO;
    
    int taxiSumCount = 0;
    
    [self.mapView removeAnnotations:self.taxiList];
    NSMutableArray *taxiListTmp = [[NSMutableArray alloc] init];
    for (NSData *realData in dataArray)
    {
        NSUInteger len = [realData length];
        Byte *realDataByteArray = (Byte*)malloc(len);
        memcpy(realDataByteArray, [realData bytes], len);
        
        
        NSData *taxiCountData = [Common reversedData:[realData subdataWithRange:NSMakeRange(MESSAGE_BODY_START_INDEX, 2)]];
        ushort taxiCount =  *(const UInt16 *)[taxiCountData bytes];
        taxiSumCount += taxiCount;
        
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
            if (userLongitude == 0 || userLatitude == 0)
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
        
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
    
    NSArray *sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
    [taxiListTmp sortUsingDescriptors:sortDescriptors];
    
    self.taxiList = taxiListTmp;
    
    
    [self.mapView addAnnotations:self.taxiList];
    [self showTaxionMapView:taxiListTmp Count:5];
    
    //self.mapView se
    
    NSString *info = [[NSString alloc] initWithFormat:@"搜索到%d辆出租车！(范围:%d公里)",taxiSumCount,[OperateAgreement Range]];
    [SGInfoAlert showInfo:info bgColor:[[UIColor darkGrayColor] CGColor]
                   inView:self.view vertical:0.7];
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




#pragma mark SearchTaxi


- (IBAction)searchTaxi:(id)sender
{
    
    if (isSearching) return;
    
    trySearchTaxiCount = 1;
    [SVProgressHUD showWithStatus:@"正在搜索附近出租车..."];
    isSearching = YES;
    
    //定时器
    NSTimer *showTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                          target:self
                                                        selector:@selector(searchTaxiThread:)
                                                        userInfo:nil
                                                         repeats:YES];
    [showTimer fire];
    
    
    
    //    dispatch_queue_t downloadQueue=dispatch_queue_create("flickr downloader", NULL);
    //
    //    dispatch_async(downloadQueue, ^{
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //
    //
    //       });
    //
    //    });
    
    //    NSString *aString = @"1234abcd";
    //
    //    NSData *aData = [aString dataUsingEncoding: NSUTF8StringEncoding];
    
    //    dispatch_queue_t downloadQueue=dispatch_queue_create("flickrphoto downloader", NULL);
    //    dispatch_async(downloadQueue, ^{
    //
    //    });
}


- (void)searchTaxiThread:(NSTimer *)theTimer
{
    if (trySearchTaxiCount > 3)
    {
        if (isSearching)
        {
            [SVProgressHUD dismissWithError:@"搜车请求超时..." afterDelay:2];
        }
        isSearching = NO;
        
        [theTimer invalidate];
        return;
    }
    
    if (isSearching)
    {
        //--------------------------Login
        [self sendData:[OperateAgreement GetSearchTaxiDataWithLatitude:self.mapView.centerCoordinate.latitude
                                                          andLongitude:self.mapView.centerCoordinate.longitude
                                                                 range:[OperateAgreement Range]]];
    }
    else
    {
        [theTimer invalidate];
    }
    
    trySearchTaxiCount ++;
}

#pragma mark UserPhoneNumber AlertView



- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag ==100 && buttonIndex == 0)
    {
        // ok button
        UITextField *textField = (UITextField *)[actionSheet viewWithTag:101];
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
    
    
}


#pragma mark Initialization MapView、CurrentPostionButton

- (void)InitializationConfig
{
    
    // Initialization MapView、CurrentPostionButton
    [self InitializationMapView];
    [self InitializationCurrentPostionButton];
    
    NSLog(@"%@",[OperateAgreement UserPhoneNumber]);
    if ([OperateAgreement UserPhoneNumber].length == 0)
    {
        [self.phoneNumberAlertView show];
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
    //if (longitude == 0 || latitude == 0)
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
    [self.currentPostionButton addTarget:self action:@selector(startShowingUserHeading:) forControlEvents:UIControlEventTouchUpInside];
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

- (IBAction) startShowingUserHeading:(id)sender
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

#pragma mark MKMapView Delegate

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
    
    //    NSString *info = [NSString stringWithFormat:@"您确认与车牌号为%@的司机通话吗？",taxiInfo.licenseplatenumber];
    //    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:info
    //                              delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
    //
    //    //alertView.
    //    alertView.tag = 101;
    //    [alertView show];
    
    if (taxiInfo)
    {
        [Common makeCall:taxiInfo.phoneNumber];
        NSData *sendData = [OperateAgreement GetSendTransactionData:taxiInfo.phoneNumber];
        [self sendData:sendData];
        [OperateAgreement SaveCallTaxiRecordWhitDriverPhoneNumber:taxiInfo.phoneNumber
                                            andLicenseplatenumber:taxiInfo.licenseplatenumber];
        
    }
}





- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    //    TaxiInfo *taxiInfo = view.annotation;
    //    NSLog(@"%f",taxiInfo.distanceFromUser);
    //    //NSLog(@" didSelectAnnotationView");
    //
    //    if ([view.annotation isKindOfClass:[TaxiInfo class]])
    //    {
    //        TaxiInfo *taxiInfo = view.annotation;
    //        NSData *sendData = [OperateAgreement GetSendTransactionData:taxiInfo.phoneNumber];
    //        [self sendData:sendData];
    //    }
    //    else
    //    {
    //        NSLog(@"no  taxiclass didSelectAnnotationView");
    //    }
    return;
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
            NSLog(@"drag ended");
            [self.spinner stopAnimating];
            getCurrentPostioning = FALSE;
            [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: NO];
            UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
            [self.currentPostionButton setImage:buttonArrow forState:UIControlStateNormal];
        }
    }
}




#pragma mark CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self.locationManager stopUpdatingLocation];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude] forKey:LAST_UESRLOCATION_LATITUDE];
    [ud setObject:[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude] forKey:LAST_UESRLOCATION_LONGITUDE];
    
    
    //    NSLog(@"%f",newLocation.verticalAccuracy);
    //    NSLog(@"%f",newLocation.horizontalAccuracy);
    
    NSLog(@"%f,%f",newLocation.coordinate.latitude - self.mapView.userLocation.coordinate.latitude
          ,newLocation.coordinate.longitude - self.mapView.userLocation.coordinate.longitude);
}



//当设备无法定位当前我位置时候调用此方法
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSString *errorType = (error.code == kCLErrorDenied)?@"Access Denied" : @"Unknown Error";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error getting Location"
                                                    message:errorType
                                                   delegate:nil
                                          cancelButtonTitle:@"oKay"
                                          otherButtonTitles: nil];
    [self.spinner stopAnimating];
    [alert show];
}



//#pragma mark - 摇一摇
//
//
//- (BOOL) canBecomeFirstResponder
//{
//    return YES;
//}
//
//
//- (void) motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
//{
//    if (motion == UIEventSubtypeMotionShake)
//    {
//        [self PlayShakeMusic];
//        [self searchTaxi:nil];
//    }
//}

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
    if (motion == UIEventSubtypeMotionShake) {
        //        NSLog(@"Shake..........");
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        [self PlayShakeMusic];
        [self searchTaxi:nil];
        
    }
}

//- (void)


#pragma mark - 实现摇一摇播放声音方法
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
