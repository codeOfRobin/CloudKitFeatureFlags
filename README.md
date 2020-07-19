# CloudKitFeatureFlags

![Swift](https://github.com/codeOfRobin/CloudKitFeatureFlags/workflows/Swift/badge.svg?branch=main)

## Features (hah!):

- Rollouts in 10% increments (10%, 20%, 30% etc.)
- A unique statistical approach, we don't need to store a large number of records or do lots of operations to rollback/deploy feature flags.
- Most operations typically involve editing one row in your CK Public database.
- All operations take place via the public databse, so no worrying about users running out of iCloud space.
- Tests to ensure rollouts are reasonably accurate (there's tests to ensure rollouts are at least 0.5% accurate on user populations of 100k users, and 1% accurate on 10k users)
- (Coming soon) Release features to specific allow-listed users - such as app reviewers
- (Coming Soon) Admin interface to create and deploy feature flags
- (Coming Soon) Gate feature flags to avoid leaking features currently in development, may require a CloudKit Schema migration

Broad ideas and implementation ideas here: https://www.craft.do/s/VIzO95A9chLeoW

Test application here: https://github.com/codeOfRobin/TestingCloudKitFeatureFlags (requires setting up a CloudKit container and changing the signing capabilities with your  Developer account)

# Guide

## Installation

Add to your project via Swift Package manager, package URL: `https://github.com/codeOfRobin/CloudKitFeatureFlags`. Since we're still early along, it's recommended to use the `main` branch.

## Usage

- Create feature flags somehow You can use the test app, or simply do it via the CloudKit dashboard. This is roughly the schema you're looking for (I'm working on making this experience better, feel free to open an issue if you need help!) ![](https://i.imgur.com/Zj6MmGR.png)
- In your app, install the package and create an instance of `CloudKitFeatureFlagsRepository`

```swift
let container = CKContainer(identifier: "<your container goes here, please make sure it's correctly set up in the "Signing & Capabilities section in Xcode>")

lazy var featureFlags = CloudKitFeatureFlagsRepository(container: container)

/// For Combine reasons
var cancellables = Set<AnyCancellable>()
```

- Use the `featureFlagsRepository` to query the status of a feature flag. In the future ([coming soon!](https://github.com/codeOfRobin/CloudKitFeatureFlags/issues/1)) it'll update realtime via a `CKSubscription`

```swift
featureFlags.featureEnabled(name: "some_feature_flag").sink(receiveCompletion: { (_) in }) { (value) in
      /// use `value` to change your UI imperatively, or bind the publisher directly!
			print(value)
		}.store(in: &cancellables)
```

- And that's it! You can control feature flags and rollouts directly from the CloudKit dashboard 🎉🎉🎉
