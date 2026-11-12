# Axie Duel changes to the Capacitor Xcode project (runs on macOS CI after `cap add ios`).
#   ruby native/ios/patch-project.rb ios/App/App.xcodeproj
# - iPhone only, iOS 15+, entitlements (push), privacy manifest, no Mac / Vision Pro "designed for iPhone".
# - AppUITests target + shared schemes "App" (build/archive) and "AppUITests" (simulator UI test).
# - Release signing (manual, Apple Distribution + "Axie Duel App Store" profile) only when TEAM_ID is set (release workflow).
require 'xcodeproj'

path = ARGV[0] or abort('usage: patch-project.rb path/to/App.xcodeproj')
project = Xcodeproj::Project.open(path)
app = project.targets.find { |t| t.name == 'App' } or abort('App target not found')
app_group = project.main_group.find_subpath('App', false) or abort('App group not found')

app.build_configurations.each do |config|
  s = config.build_settings
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  s['CODE_SIGN_ENTITLEMENTS'] = 'App/App.entitlements'
  s['SUPPORTS_MACCATALYST'] = 'NO'
  s['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  s['SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
end

# Files copied next to AppDelegate.swift that the template project does not reference yet.
app_group.new_reference('App.entitlements') unless app_group.files.any? { |f| f.path == 'App.entitlements' }
unless app_group.files.any? { |f| f.path == 'PrivacyInfo.xcprivacy' }
  privacy = app_group.new_reference('PrivacyInfo.xcprivacy')
  app.resources_build_phase.add_file_reference(privacy, true)
end

team = ENV['TEAM_ID'].to_s.strip
unless team.empty?
  app.build_configurations.select { |c| c.name == 'Release' }.each do |config|
    s = config.build_settings
    s['CODE_SIGN_STYLE'] = 'Manual'
    s['DEVELOPMENT_TEAM'] = team
    s['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
    s['PROVISIONING_PROFILE_SPECIFIER'] = 'Axie Duel App Store'
  end
end

# UI test target (simulator only; never archived).
tests = project.targets.find { |t| t.name == 'AppUITests' }
unless tests
  tests = project.new_target(:ui_test_bundle, 'AppUITests', :ios, '15.0')
  tests.add_dependency(app)
  group = project.main_group.find_subpath('AppUITests', false) || project.main_group.new_group('AppUITests', 'AppUITests')
  source = group.new_reference('AppUITests.swift')
  tests.add_file_references([source])
end
tests.build_configurations.each do |config|
  s = config.build_settings
  s['TEST_TARGET_NAME'] = 'App'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.axieduel.app.uitests'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  s['CODE_SIGNING_ALLOWED'] = 'NO'
end

project.save

app_scheme = Xcodeproj::XCScheme.new
app_scheme.add_build_target(app)
app_scheme.set_launch_target(app)
app_scheme.save_as(path, 'App', true)

test_scheme = Xcodeproj::XCScheme.new
test_scheme.add_build_target(app)
test_scheme.add_test_target(tests)
test_scheme.set_launch_target(app)
test_scheme.save_as(path, 'AppUITests', true)

puts "patched #{path}: App (iPhone, iOS 15+, push entitlements, privacy manifest#{team.empty? ? '' : ', release signing'}) + AppUITests"
