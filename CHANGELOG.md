Branch Mac SDK Change Log

## 1.4.1 - May 9, 2023

SDK-1905
Fix for build issue with Xcode 14.3 and Swift 5.8

INTENG-17551 
Added developer_identity to v2/event requests

## 1.4.0 - Aug 16, 2022

SDK-1405
Branch QR codes functionality added.

SDK-1205 
Fixed Set Identity Issue.  

SDK-1373, SDK-1374 
Renamed device_fingerprint_id and identity_id to better reflect functionality. Fingerprinting was removed long ago. 

SDK-1346
Exposed setRequestMetadata API. 

SDK-1530
Developer id added in v1/open requests.

## v1.3.1 - Jun 2, 2021

CORE-1989
Add getUserIdentity to the public API

CORE-1659
Add INITIATE_STREAM and COMPLETE_STREAM to standard events

Test coverage improvements

## v1.3.0 - Jan 28, 2021

CORE-1303
Improve integration options for the macOS SDK by adding support for Swift Package Manager, Carthage and Cocoapods. See the Branch docs site for more details.

Improve test coverage and test automation. This may impact you if you are importing the Branch macOS SDK as source.

## v1.2.5 - Oct 8, 2020
* Allow short link generation when tracking is disabled

## v1.2.4 - June 17, 2020
* Remove certificate pinning

## v1.2.3 - May 13, 2020
* Fix control param location in request payload

## v1.2.2 - May 7, 2020
* Fix fallback when idfa is not available

## v1.2.1 - December 13, 2019
* Fix crash when idfa is not available

## v1.2.0 - October 7, 2019
* Add user agent
* Attribution fixes

## v1.1.0 - December 6th, 2018
* Added tvOS support
* Added CocoaPod support

## v0.1.0-beta - *First Release - July 13, 2018*

Branch is proud to release the beta version of the Branch SDK for Mac!

Thank you @Sarkar, @ahmednawar, @clayjones94, @aaaronlopez and @GeneShay!

We welcome your feedback, suggestions and bugs reports. You can add them in [here, in issues area here on GitHub.](https://github.com/BranchMetrics/mac-branch-deep-linking/issues)

For installation and usage instructions check out the [Readme](https://github.com/BranchMetrics/mac-branch-deep-linking/blob/master/README.md) and the [documentation](https://branchmetrics.github.io/mac-branch-deep-linking/index.html).

Happy linking!
@E-B-Smith
