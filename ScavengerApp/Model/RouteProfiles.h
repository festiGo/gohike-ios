//
//  SelectionScreen.h
//
//  Created by Giovanni Maggini on 5/16/13
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface RouteProfiles : NSObject <NSCoding>

@property (nonatomic, strong) NSString *lastupdate;
@property (nonatomic, strong) NSArray *profiles;

+ (RouteProfiles *)modelObjectWithDictionary:(NSDictionary *)dict;
- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
