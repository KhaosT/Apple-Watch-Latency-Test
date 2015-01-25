//
//  MethodHelper.m
//  WatchClient
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

#import "MethodHelper.h"

@implementation MethodHelper

+ (void) performActionForObject:(id)object selector:(SEL)selector WithParm:(id)parm {
    [object performSelectorOnMainThread:selector withObject:parm waitUntilDone:YES];
}

@end
