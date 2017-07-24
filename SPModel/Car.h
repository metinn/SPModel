//
//  Car.h
//  PersistedModel
//
//  Created by Metin Güler on 20/07/2017.
//  Copyright © 2017 RDC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPModel.h"

@interface Car : SPModel

@property (nonatomic, strong) NSString *marka;
@property (nonatomic, strong) NSString *model;
@property (nonatomic) int yil;
@property (nonatomic) double tuketim;
@property (nonatomic) NSNumber *km;

@end
