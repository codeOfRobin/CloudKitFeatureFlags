# CloudKitFeatureFlags

![Swift](https://github.com/codeOfRobin/CloudKitFeatureFlags/workflows/Swift/badge.svg?branch=main)

## Features (hah!):

- Rollouts in 10% increments (10%, 20%, 30% etc.)
- A unique statistical approach, we don't need to store a large number of records or do lots of operations to rollback/deploy feature flags.
- Most operations typically involve editing one row in your CK Public database.
- All operations take place via the public databse, so no worrying about users running out of iCloud space.
- (Coming soon) Release features to specific allow-listed users - such as app reviewers
- (Coming Soon) Admin interface to create and deploy feature flags
- (Coming Soon) Gate feature flags to avoid leaking features currently in development, may require a CloudKit Schema migration

Broad ideas and implementation ideas here: https://www.craft.do/s/VIzO95A9chLeoW

Test application here: https://github.com/codeOfRobin/TestingCloudKitFeatureFlags (requires setting up a CloudKit container and changing the signing capabilities with your  Developer account)
