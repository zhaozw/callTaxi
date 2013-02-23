//
//  CustomAnnotationView.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-21.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "CustomAnnotationView.h"
#import "BusStationInfo.h"

@implementation CustomAnnotationView



- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    if ([annotation isKindOfClass:[BusStationInfo class]]) //handle station icon
    {
        BusStationInfo* busStationInfo = (BusStationInfo*)annotation;
        
        self = [super initWithAnnotation:busStationInfo reuseIdentifier:reuseIdentifier];
        self.frame = CGRectMake(0, 0, 30, 30);
        self.backgroundColor = [UIColor clearColor];
        
        UILabel *mylable= [[UILabel alloc] init];
        mylable.text= busStationInfo.stationName;
        UIFont *font = [UIFont systemFontOfSize:10];
        mylable.font = font;
        mylable.backgroundColor = [UIColor greenColor];
        mylable.textColor = [UIColor blueColor];
        mylable.frame = CGRectMake(-30, 0, 60, 20);
        mylable.backgroundColor = [UIColor clearColor];        
        [self addSubview:mylable];
        
        self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"station.png"]];
        self.imageView.frame = CGRectMake(-30, 18, 27, 27);
        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [self addSubview:self.imageView];

        self.centerOffset = CGPointMake(50,-13);


    }
    return self;
}



/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
