//
//  SKYNotificationInfo.m
//  askq
//
//  Created by Kenji Pa on 29/1/15.
//  Copyright (c) 2015 Rocky Chan. All rights reserved.
//

#import "SKYNotificationInfo.h"

static BOOL isNilOrEqualArray(NSArray *a1, NSArray *a2)
{
    return (a1 == nil && a2 == nil) || [a1 isEqualToArray:a2];
}

@implementation SKYNotificationInfo

+ (instancetype)notificationInfo
{
    return [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone
{
    SKYNotificationInfo *info = [[self.class allocWithZone:zone] init];

    info->_apsNotificationInfo = [_apsNotificationInfo copyWithZone:zone];
    info->_gcmNotificationInfo = [_gcmNotificationInfo copyWithZone:zone];
    info->_desiredKeys = [_desiredKeys copyWithZone:zone];

    return info;
}

- (BOOL)isEqual:(id)object
{
    if (!object) {
        return NO;
    }

    if (![object isKindOfClass:SKYNotificationInfo.class]) {
        return NO;
    }

    return [self isEqualToNotificationInfo:object];
}

- (BOOL)isEqualToNotificationInfo:(SKYNotificationInfo *)n
{
    return (((self.apsNotificationInfo == nil && n.apsNotificationInfo == nil) ||
             [self.apsNotificationInfo isEqualToNotificationInfo:n.apsNotificationInfo]) &&
            ((self.gcmNotificationInfo == nil && n.gcmNotificationInfo == nil) ||
             [self.gcmNotificationInfo isEqualToNotificationInfo:n.gcmNotificationInfo]) &&
            isNilOrEqualArray(self.desiredKeys, n.desiredKeys));
}

- (NSUInteger)hash
{
    return self.apsNotificationInfo.hash ^ self.gcmNotificationInfo.hash ^ self.desiredKeys.hash;
}

- (NSString *)description
{
    return
        [NSString stringWithFormat:
                      @"%@ <apsNotificationInfo = %@, gcmNotificationInfo = %@, desiredKeys = %@>",
                      NSStringFromClass(self.class), self.apsNotificationInfo,
                      self.gcmNotificationInfo, self.desiredKeys];
}

@end