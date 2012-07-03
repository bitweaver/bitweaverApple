//
//  BitcommerceProduct.h
//  PBPro API Demo
//
//  Created by Christian Fowler on 6/27/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

#import "LibertyBase.h"

@interface BitcommerceProduct : LibertyBase

@property (nonatomic,strong) NSNumber *productId;
@property (nonatomic,strong) NSNumber *ratioId;
@property (nonatomic,strong) NSString *typeClass;

+ (BitcommerceProduct *)productFromHash:(NSDictionary *)hash;

@end
