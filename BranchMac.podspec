Pod::Spec.new do |s|
  s.name             = 'BranchMac'
  s.version          = '1.1.0'
  s.summary          = 'Create an HTTP URL for any piece of content in your macOS or tvOS app.'
  s.description      = <<-DESC
- Want the highest possible conversions on your sharing feature?
- Want to measure the k-factor of your invite feature?
- Want a whole referral program in 10 lines of code, with automatic user-user attribution and rewarding?
- Want to pass data (deep link) from a URL across install and open?
- Want custom onboarding post install?
- Want it all for free?

Use the Branch SDK (branch.io) to create and power the links that point back to your apps for all of these things and more. Branch makes it incredibly simple to create powerful deep links that can pass data across app install and open while handling all edge cases (using on desktop vs. mobile vs. already having the app installed, etc). Best of all, it's really simple to start using the links for your own app: only 2 lines of code to register the deep link router and one more line of code to create the links with custom data.
                       DESC

  s.homepage         = "https://branch.io"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Branch Metrics" => "support@branch.io" }
  s.source           = { git: "https://github.com/BranchMetrics/mac-branch-deep-linking.git", tag: s.version.to_s }
  s.social_media_url = 'https://twitter.com/branchmetrics'

  s.osx.deployment_target   = '10.10'
  s.tvos.deployment_target  = '9.0'

  s.source_files = 'Branch/**/*'

end
