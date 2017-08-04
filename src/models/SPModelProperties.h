//
//  SPModelProperties.h
//  PersistedModel
//
//  Created by Metin Güler on 23/07/2017.
//  Copyright © 2017 Metin Güler. All rights reserved.
//

#import "SPModel.h"

@interface SPModelProperties : SPModel
@property (nonatomic) int64_t fk_spmodeltable;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *type;

@end
