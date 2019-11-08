project 'ChristmasCheer.xcodeproj/'

# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '5.0'
        end
    end
end

def shared_pods
  use_frameworks!

  pod 'Parse'

#  pod 'Genome'

  pod 'Cartography'
  pod 'Yams'

  pod 'Fabric'
  pod 'Crashlytics'
end

target 'ChristmasCheer' do
  shared_pods
end

target 'ChristmasCheerDevelopment' do
  shared_pods
end
