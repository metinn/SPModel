//
//  Person.h
//  PersistedModel
//
//  Created by Metin Güler on 23/07/2017.
//  Copyright © 2017 RDC. All rights reserved.
//

#import "SPModel.h"
#import "Car.h"

@interface Person : SPModel
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *surname;
@property (nonatomic) NSString *number;
@property (nonatomic) NSInteger age;
@property (nonatomic) long long money;

@property (nonatomic) Car *car;
@end
