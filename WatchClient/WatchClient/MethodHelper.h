//
//  MethodHelper.h
//  WatchClient
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MethodHelper : NSObject

+ (void) performActionForObject:(id)object selector:(SEL)selector WithParm:(id)parm;

@end
