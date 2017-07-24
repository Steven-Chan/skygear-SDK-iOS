//
//  SKYRevokeUserRoleOperation.m
//  SKYKit
//
//  Copyright 2017 Oursky Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SKYRevokeUserRoleOperation.h"

@implementation SKYRevokeUserRoleOperation

+ (instancetype)operationWithUsers:(NSArray<SKYRecord *> *)users roles:(NSArray<SKYRole *> *)roles
{
    return [[self alloc] initWithUsers:users roles:roles completionBlock:nil];
}

- (instancetype)initWithUsers:(NSArray<SKYRecord *> *)users
                        roles:(NSArray<SKYRole *> *)roles
              completionBlock:
                  (void (^)(NSArray<NSString *> *userIDs, NSError *error))completionBlock
{
    self = [super init];
    if (self) {
        self.users = users;
        self.roles = roles;
        self.revokeUserRoleCompletionBlock = completionBlock;
    }
    return self;
}

- (NSArray<NSString *> *)userIDs
{
    NSMutableArray<NSString *> *userIDs = [NSMutableArray arrayWithCapacity:self.users.count];
    for (SKYRecord *user in self.users) {
        if (![user.recordID.recordType isEqualToString:@"user"]) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"Record type should be user"
                                         userInfo:nil];
        }

        [userIDs addObject:user.recordID.recordName];
    }

    return userIDs;
}

- (NSArray<NSString *> *)roleNames
{
    NSMutableArray<NSString *> *roleNames = [NSMutableArray arrayWithCapacity:self.roles.count];
    for (SKYRole *role in self.roles) {
        [roleNames addObject:role.name];
    }

    return roleNames;
}

// override
- (void)prepareForRequest
{
    self.request = [[SKYRequest alloc] initWithAction:@"role:revoke"
                                              payload:@{
                                                  @"users" : self.userIDs,
                                                  @"roles" : self.roleNames,
                                              }];
    self.request.APIKey = self.container.APIKey;
    self.request.accessToken = self.container.auth.currentAccessToken;
}

// override
- (void)operationWillStart
{
    [super operationWillStart];
    if (!self.container.auth.currentAccessToken) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"SKYContainer has no currently logged-in user"
                                     userInfo:nil];
    }
}

// override
- (void)handleRequestError:(NSError *)error
{
    if (self.revokeUserRoleCompletionBlock) {
        self.revokeUserRoleCompletionBlock(nil, error);
    }
}

// override
- (void)handleResponse:(SKYResponse *)aResponse
{
    if (self.revokeUserRoleCompletionBlock) {
        self.revokeUserRoleCompletionBlock(self.userIDs, nil);
    }
}

@end
