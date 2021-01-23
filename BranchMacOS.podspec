Pod::Spec.new do |spec|
  spec.name         = "BranchMacOS"
  spec.version      = "1.2.5"
  spec.summary      = "Create an HTTP URL for any piece of content in your MacOS app"
  spec.description  = <<-DESC
  - Want the highest possible conversions on your sharing feature?
- Want to measure the k-factor of your invite feature?
- Want a whole referral program in 10 lines of code, with automatic user-user attribution and rewarding?
- Want to pass data (deep link) from a URL across install and open?
- Want custom onboarding post install?

Use the Branch SDK (branch.io) to create and power the links that point back to your apps for all of these things and more. Branch makes it incredibly simple to create powerful deep links that can pass data across app install and open while handling all edge cases (using on desktop vs. mobile vs. already having the app installed, etc). Best of all, it's really simple to start using the links for your own app: only 2 lines of code to register the deep link router and one more line of code to create the links with custom data.
                   DESC
  spec.homepage     = "https://help.branch.io/developers-hub/docs/mac-os-sdk-overview"
  spec.license      = "MIT"
  spec.author       = { "Branch" => "support@branch.io" }
  spec.source       = { git: "https://github.com/BranchMetrics/mac-branch-deep-linking.git", tag: spec.version.to_s  }
  spec.osx.deployment_target   = "10.10"
  spec.source_files = "Branch/*.{h,m}"
  spec.frameworks = "WebKit" , "AdSupport"
  spec.header_dir   = 'Branch'
end
