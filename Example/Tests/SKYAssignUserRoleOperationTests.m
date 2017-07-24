//
//  SKYAssignUserRoleOperationTests.m
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

#import <Foundation/Foundation.h>
#import <SKYKit/SKYKit.h>

SpecBegin(SKYAssignUserRoleOperation)

    describe(@"Assign User Role Operation", ^{
        NSString *apiKey = @"CORRECT_KEY";
        NSString *currentUserID = @"CORRECT_USER_ID";
        NSString *token = @"CORRECT_TOKEN";

        NSString *developerRoleName = @"Developer";
        NSString *testerRoleName = @"Tester";

        SKYRole *developerRole = [SKYRole roleWithName:developerRoleName];
        SKYRole *testerRole = [SKYRole roleWithName:testerRoleName];

        SKYRecord *user1 = [SKYRecord recordWithRecordType:@"user" name:@"user1"];
        SKYRecord *user2 = [SKYRecord recordWithRecordType:@"user" name:@"user2"];
        SKYRecord *user3 = [SKYRecord recordWithRecordType:@"user" name:@"user3"];

        __block SKYContainer *container;

        beforeEach(^{
            container = [[SKYContainer alloc] init];
            [container configureWithAPIKey:apiKey];
            [container.auth
                updateWithUserRecordID:currentUserID
                           accessToken:[[SKYAccessToken alloc] initWithTokenString:token]];
        });

        it(@"should create SKYRequest correctly", ^{
            SKYAssignUserRoleOperation *operation =
                [SKYAssignUserRoleOperation operationWithUsers:@[ user1, user2, user3 ]
                                                         roles:@[ developerRole, testerRole ]];

            [operation setContainer:container];
            [operation prepareForRequest];

            SKYRequest *request = operation.request;
            expect(request.action).to.equal(@"role:assign");
            expect(request.accessToken.tokenString).to.equal(token);

            expect(request.payload[@"users"]).to.equal(@[ @"user1", @"user2", @"user3" ]);
            expect(request.payload[@"roles"]).to.equal(@[ @"Developer", @"Tester" ]);
        });

        it(@"should handle success response correctly", ^{
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
            }
                withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                    NSDictionary *response = @{ @"result" : @"OK" };
                    return [OHHTTPStubsResponse responseWithJSONObject:response
                                                            statusCode:200
                                                               headers:nil];
                }];

            SKYAssignUserRoleOperation *operation =
                [SKYAssignUserRoleOperation operationWithUsers:@[ user1, user2, user3 ]
                                                         roles:@[ developerRole, testerRole ]];

            [operation setContainer:container];

            waitUntil(^(DoneCallback done) {
                operation.assignUserRoleCompletionBlock =
                    ^(NSArray<SKYRecord *> *users, NSError *error) {
                        expect(error).to.beNil();
                        expect(users).to.haveCountOf(3);
                        expect(users).to.contain(user1);
                        expect(users).to.contain(user2);
                        expect(users).to.contain(user3);

                        done();
                    };

                [container addOperation:operation];
            });
        });

        afterEach(^{
            [OHHTTPStubs removeAllStubs];
        });
    });

SpecEnd
