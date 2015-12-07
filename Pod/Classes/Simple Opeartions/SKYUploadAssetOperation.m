//
//  SKYAssetUploadOperation.m
//  Pods
//
//  Created by Kenji Pa on 6/7/15.
//
//

#import "SKYUploadAssetOperation.h"

#import "SKYAsset_Private.h"
#import "SKYDataSerialization.h"
#import "SKYOperation+OverrideLifeCycle.h"
#import "NSURLRequest+SKYRequest.h"

@interface SKYUploadAssetOperation ()

@property (nonatomic, readwrite) NSURLSession *session;
@property (nonatomic, readwrite) NSURLSessionUploadTask *task;

@end

@implementation SKYUploadAssetOperation

- (instancetype)initWithAsset:(SKYAsset *)asset
{
    self = [super init];
    if (self) {
        _session = [NSURLSession
            sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _asset = asset;
    }
    return self;
}

+ (instancetype)operationWithAsset:(SKYAsset *)asset
{
    return [[self alloc] initWithAsset:asset];
}

#pragma mark - NSOperation

- (void)start
{
    if (self.cancelled || self.executing || self.finished) {
        return;
    }

    [self operationWillStart];

    [self setExecuting:YES];

    BOOL shouldObserveProgress = self.uploadAssetProgressBlock != nil;

    NSURLRequest *request = [self makeRequest];
    __weak typeof(self) weakSelf = self;
    self.task = [self.session
        uploadTaskWithRequest:request
                     fromFile:self.asset.url
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;

                [strongSelf handleCompletionWithData:data response:response error:error];

                if (shouldObserveProgress) {
                    [strongSelf.task
                        removeObserver:self
                            forKeyPath:NSStringFromSelector(@selector(countOfBytesSent))
                               context:nil];
                }

                [strongSelf setExecuting:NO];
                [strongSelf setFinished:YES];
            }];

    if (shouldObserveProgress) {
        [self.task addObserver:self
                    forKeyPath:NSStringFromSelector(@selector(countOfBytesSent))
                       options:0
                       context:nil];
    }

    [self.task resume];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([object isKindOfClass:[NSURLSessionUploadTask class]]) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesSent))]) {
            NSURLSessionUploadTask *task = object;

            // task.countOfBytesExpectedToSend sometimes returns zero for unknown reason
            // since we are saving asset data in file anyway, we access the value from asset
            // instead.
            self.uploadAssetProgressBlock(self.asset, task.countOfBytesSent * 1.0 /
                                                          self.asset.fileSize.integerValue);
        }
    }
}

#pragma mark - Other methods

- (NSURLRequest *)makeRequest
{
    NSURL *baseURL = [NSURL URLWithString:@"files/" relativeToURL:self.container.endPointAddress];
    NSURL *url = [NSURL URLWithString:self.asset.name relativeToURL:baseURL];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"PUT";

    // SkyKit-related headers
    NSString *apiKey = self.container.APIKey;
    if (apiKey.length) {
        [request setValue:self.container.APIKey forHTTPHeaderField:SKYRequestHeaderAPIKey];
    }
    NSString *accessTokenString = self.container.currentAccessToken.tokenString;
    if (accessTokenString) {
        [request setValue:accessTokenString forHTTPHeaderField:SKYRequestHeaderAccessTokenKey];
    }

    return request;
}

- (void)handleCompletionWithData:(NSData *)data
                        response:(NSURLResponse *)response
                           error:(NSError *)error
{
    NSDictionary *result = nil;
    if (!error) {
        result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    }

    if (!error) {
        NSDictionary *rawAsset = result[@"result"];
        NSString *name = rawAsset[@"$name"];
        if (name.length) {
            _asset.name = name;
        } else {
            error = [NSError errorWithDomain:SKYOperationErrorDomain code:0 userInfo:nil];
        }
    }

    if (self.uploadAssetCompletionBlock) {
        self.uploadAssetCompletionBlock(_asset, error);
    }
}

@end