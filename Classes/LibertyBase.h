//
//  LibertyBase.h
//  Liberty
//
//  Created by Christian Fowler on 11/15/11.
//  Copyright 2011 Viovio.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibertyBase : NSObject {
    NSString *_bookId;
}

@property (nonatomic,strong) NSString *bookId;

- (NSString *)generateId;
- (BOOL) createDirectory:(NSString *)directory;

// REST Mappable properties
@property (nonatomic,strong) NSString *uuId;
@property (nonatomic,strong) NSNumber *userId;
@property (nonatomic,strong) NSDate *dateCreated;
@property (nonatomic,strong) NSDate *dateLastModified;


- (NSDictionary*)getReceivablePropertyMappings;
- (NSDictionary*)getSendablePropertyMappings;
- (void)loadFromRemoteProperties:(NSDictionary *)remoteHash;

@end

