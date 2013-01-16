//
//  DTAccelerometerBTService.h
//  Deanna
//
//  Created by Charles Choi on 12/18/12.
//  Copyright (c) 2012 Yummy Melon Software. All rights reserved.
//

#import "DEABaseService.h"

@interface DEAAccelerometerService : DEABaseService

@property (nonatomic, strong) NSNumber *x;
@property (nonatomic, strong) NSNumber *y;
@property (nonatomic, strong) NSNumber *z;

- (void)updateAcceleration;

@end