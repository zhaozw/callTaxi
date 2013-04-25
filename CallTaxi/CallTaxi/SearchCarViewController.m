//
//  SearchCarViewController.m
//  CallTaxi
//
//  Created by Fan Lv on 13-4-24.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "SearchCarViewController.h"
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NSData+Hex.h"
#import "AsyncUdpSocket.h"
#import "OperateAgreement.h"
#import "Common.h"
#import "SVProgressHUD.h"
#import "SGInfoAlert.h"
#import "CarInfo.h"

@interface SearchCarViewController ()<MKMapViewDelegate,CLLocationManagerDelegate,UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIButton *currentPostionButton;
@property (strong,nonatomic) AsyncUdpSocket *socket;
@property (strong,nonatomic) UIActivityIndicatorView *spinner;
@property (strong,nonatomic) NSArray *carList;
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) NSTimer *searchTaxiTimer;


@property (nonatomic,assign) BOOL isGetUserLocation; //didSelectTaxiInfo
@property (nonatomic,assign) BOOL getCurrentPostioning;
@property (nonatomic,strong) CarInfo *didSelectCarInfo;
@property (nonatomic,assign) int trySearchTaxiCount;
@property (nonatomic,assign) BOOL isSearching;
@property (nonatomic,assign) BOOL isStartReceTaxiInfo;
@property (nonatomic,assign) short receTaxiInfoCurrentPacIndex;

//isSearching = YES;
//isStartReceTaxiInfo = NO;
//trySearchTaxiCount = 1;
//short  = -1;


@end

@implementation SearchCarViewController

@synthesize currentPostionButton = _currentPostionButton;
@synthesize mapView = _mapView;
@synthesize spinner = _spinner;
@synthesize socket = _socket;
@synthesize carList = _carList;
@synthesize locationManager = _locationManager;
@synthesize searchTaxiTimer = _searchTaxiTimer;

#pragma mark - @property


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



#pragma mark - Initialization MapView、CurrentPostionButton

- (void)InitializationConfig
{
    
    // Initialization MapView、CurrentPostionButton
    [self InitializationMapView];
    [self InitializationCurrentPostionButton];
    
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
    
    if (self.isGetUserLocation == NO)
    {
        self.getCurrentPostioning = YES;
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

#pragma mark - MKMapView Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    
    if ([annotation isKindOfClass:[CarInfo class]])
    {
        CarInfo *carInfo = annotation;
        MKAnnotationView *aView=[mapView dequeueReusableAnnotationViewWithIdentifier:@"car"];
        if (!aView)
        {
            aView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"car"];
            aView.canShowCallout = YES;
            
            aView.image = [OperateAgreement GetTaxiImageWithAngle:carInfo.angle andTaxiState:0];
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
    CarInfo *carInfo = av.annotation;
    
    if (carInfo)
    {
        [Common makeCall:carInfo.phoneNumber];
    }
}





- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    self.didSelectCarInfo = view.annotation;
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
    if (self.isGetUserLocation == NO)
    {
        self.isGetUserLocation = YES;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:[NSString stringWithFormat:@"%f",userLocation.coordinate.latitude] forKey:LAST_UESRLOCATION_LATITUDE];
        [ud setObject:[NSString stringWithFormat:@"%f",userLocation.coordinate.longitude] forKey:LAST_UESRLOCATION_LONGITUDE];
        [ud synchronize];
        
    }
    if(self.getCurrentPostioning)
    {
        self.getCurrentPostioning = FALSE;
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
        if (self.getCurrentPostioning)
        {
            [self.spinner stopAnimating];
            self.getCurrentPostioning = FALSE;
            [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: NO];
            UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
            [self.currentPostionButton setImage:buttonArrow forState:UIControlStateNormal];
        }
    }
}




#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];


    [self InitializationConfig];
    self.isGetUserLocation = NO;
    

    
    //  check LocationManager
    if ([CLLocationManager locationServicesEnabled])
    {
        [self.spinner startAnimating];
        [self.locationManager startUpdatingLocation];
        
       self.getCurrentPostioning = YES;
    }
    else
    {
        [self.spinner stopAnimating];
        [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: NO];
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
        [self.currentPostionButton setImage:buttonArrow forState:UIControlStateNormal];
    }}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
}


#pragma mark - UDP Delegate

- (void)sendData:(NSData * )data
{
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
    NSString *info = [NSString stringWithFormat:@"host: %@,port : %hu, data length : %lu",host,port,(unsigned long)data.length];
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


#pragma mark - searchCar

- (IBAction)searchCar:(id)sender
{
    [self searchCar];
}

- (void)searchCar
{
    if (self.isSearching)
    {
        [SGInfoAlert showInfo:@"请稍后在搜索。。。。" bgColor:[[UIColor darkGrayColor] CGColor]
                       inView:self.view vertical:0.6];
        return;
    }
    self.isSearching = YES;
    self.isStartReceTaxiInfo = NO;
    self.trySearchTaxiCount = 1;
    self.receTaxiInfoCurrentPacIndex = -1;
    
    
    [self.mapView removeAnnotations:self.carList];
    self.carList = nil;
    
    [SVProgressHUD showWithStatus:@"正在搜索附近可以拼车的私家车..."];
    self.searchTaxiTimer = nil;
    [self.searchTaxiTimer fire];
}

- (void)searchTaxiThread:(NSTimer *)theTimer
{
    if (self.trySearchTaxiCount > 2)
    {
        if (self.isSearching)
        {
            [SVProgressHUD dismissWithError:@"搜车请求超时..." afterDelay:3];
        }
        self.isSearching = NO;
    }
    
    if (self.isSearching)
    {
        if (self.isStartReceTaxiInfo == NO)
        {
            [self sendData:[OperateAgreement GetSearchCarDataWithLatitude:self.mapView.centerCoordinate.latitude
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
    self.trySearchTaxiCount ++;
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
    
    if([messageID isEqualToString:MESSAGE_ID_SEARCHCAR_REPLY])
    {
        
        [self searchCarMeaageHandling:dataArray];
    }
    else if([messageID isEqualToString:MESSAGE_ID_UPLoadTrade_REPLY])
    {
        NSLog(@"MESSAGE_ID_UPLoadTrade_REPLY");
    }
}


- (void)searchCarMeaageHandling:(NSArray *)dataArray
{
    [SVProgressHUD dismiss];
    self.isStartReceTaxiInfo = YES;
    if (self.isSearching == NO)
        return;
    
    NSMutableArray *carListTmp = [[NSMutableArray alloc] initWithArray:self.carList];
    for (NSData *realData in dataArray)
    {
        NSUInteger len = [realData length];
        Byte *realDataByteArray = (Byte*)malloc(len);
        memcpy(realDataByteArray, [realData bytes], len);
        
        
        
        ushort packageIndex =[OperateAgreement GetPackageIndexInMessageHead:realData];
        ushort packageCount =[OperateAgreement GetPackageCountInMessageHead:realData];
        
        if (self.receTaxiInfoCurrentPacIndex >= packageIndex)
            return;
        self.receTaxiInfoCurrentPacIndex = packageIndex;
//        NSLog(@"%d",packageIndex);
//        NSLog(@"%d",packageCount);
        
        NSData *taxiCountData = [Common reversedData:[realData subdataWithRange:NSMakeRange(MESSAGE_BODY_START_INDEX+1, 2)]];
        ushort taxiCount =  *(const UInt16 *)[taxiCountData bytes];
        
        for (int i = 0; i < taxiCount; i++)
        {
            CarInfo *carInfo = [[CarInfo alloc] init];
            NSInteger taxiInfoStartIndex = MESSAGE_BODY_START_INDEX + 3 + (i * 85);
            
            carInfo.longitude = [[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex, 5)]
                                   hexRepresentationWithSpaces_AS:NO] doubleValue] / pow(10, 6);
            
            carInfo.latitude = [[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex+5, 5)]
                                  hexRepresentationWithSpaces_AS:NO] doubleValue] / pow(10, 6);
            
           

            
            carInfo.phoneNumber = [[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex +15,6)] hexRepresentationWithSpaces_AS:NO] substringFromIndex:1];
            
      
            
            carInfo.angle = *(const UInt16 *)[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex + 42, 2)] bytes];
            
            carInfo.speed = realDataByteArray[taxiInfoStartIndex + 44];
            
            NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
            
            
            carInfo.personalizedSignature = [[NSString alloc] initWithData:[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex + 45, 20)] encoding:enc];
            
            //29.705172,116.005516
            double userLatitude = self.mapView.userLocation.coordinate.latitude;
            double userLongitude = self.mapView.userLocation.coordinate.longitude;
            
            
            if (userLongitude == 0 || userLatitude == 0
                || self.mapView.userLocation.location.verticalAccuracy > 300
                || self.mapView.userLocation.location.horizontalAccuracy > 300
                )
            {
                carInfo.distanceFromUser = 0;
            }
            else
            {
                CLLocation *cl1  =[[ CLLocation alloc] initWithLatitude:carInfo.latitude longitude:carInfo.longitude];
                CLLocation *cl2  =[[ CLLocation alloc] initWithLatitude:userLatitude longitude:userLongitude];
                CLLocationDistance distance = [cl1 distanceFromLocation:cl2];
                carInfo.distanceFromUser = distance;
            }
            
            [carListTmp addObject:carInfo];
            
        }
        self.carList = carListTmp;
        
        
        [self.mapView addAnnotations:self.carList];
        
        
        if (packageIndex == packageCount )
        {
            
            self.isSearching = NO;
            
            [self.searchTaxiTimer invalidate];
            self.searchTaxiTimer = nil;
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
            [carListTmp sortUsingDescriptors:sortDescriptors];
            [self showTaxionMapView:carListTmp Count:5];
            NSString *info = [[NSString alloc] initWithFormat:@"一共到%d辆私家车！(范围:%d公里)",self.carList.count,[OperateAgreement Range]];
            
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
        CarInfo *carInfo = [self.carList objectAtIndex:i];
        MKMapPoint annotationPoint = MKMapPointForCoordinate(carInfo.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
    
    
    
}




@end
