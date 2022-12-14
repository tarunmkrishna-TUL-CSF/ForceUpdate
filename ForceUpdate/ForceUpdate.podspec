 Pod::Spec.new do |spec|
 
  spec.name         = "ForceUpdate"
  spec.version      = "1.0.0"
  spec.summary      = "Alert for force update for users."
  spec.description  = "Framework to determine and forceupdate the Application for users"
  
  spec.homepage     = "https://github.com/tarunmkrishna2712/ForceUpdate"
  spec.license      = "MIT"
  spec.author             = { "tarunmkrishna2712" => "tkrishna@tataunistore.com" }
  spec.platform     = :ios, "14.0"
  spec.source       = { :git => "https://github.com/tarunmkrishna2712/ForceUpdate.git", :tag => spec.version.to_s }
  spec.source_files  = "ForceUpdate/**/*.{swift}"
  spec.swift_versions = "5.0"
  spec.framework      = 'UIKit'
end
