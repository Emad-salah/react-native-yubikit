// Copyright 2018-2019 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "YKFKeyOATHCalculateAllRequest.h"
#import "YKFKeyOATHCalculateAllRequest+Private.h"
#import "YKFOATHCalculateAllAPDU.h"
#import "YKFKeyOATHRequest+Private.h"

@implementation YKFKeyOATHCalculateAllRequest

- (instancetype)init {
    return [self initWithTimestamp: [NSDate date]];
}

- (instancetype)initWithTimestamp: (NSDate*) timestamp {
    self = [super init];
    if (self) {
        self.timestamp = timestamp;
        self.apdu = [[YKFOATHCalculateAllAPDU alloc] initWithTimestamp:self.timestamp];
    }
    return self;
}
@end
