platform :osx, '13.0'

target 'Embark' do
  use_frameworks!
  pod 'lottie-ios'
  pod 'Sparkle', '~> 2.9.4'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_MODULE_VERIFIER'] = 'NO'
      config.build_settings.delete('OTHER_MODULE_VERIFIER_FLAGS')
    end
  end

  Dir.glob(File.join(installer.sandbox.root, "Target Support Files", "**", "*.xcconfig")).each do |file|
    content = File.read(file)
    if content.include?('${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}')
      content.gsub!('"${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"', '')
      content.gsub!('${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}', '')
      File.write(file, content)
    end
    if content.include?('OTHER_MODULE_VERIFIER_FLAGS')
      content = content.lines.reject { |line| line.start_with?('OTHER_MODULE_VERIFIER_FLAGS') }.join
      File.write(file, content)
    end
  end
  lottie_helpers_path = File.join(installer.sandbox.root, "lottie-ios", "Sources", "Public", "Animation", "LottieAnimationHelpers.swift")
  if File.exist?(lottie_helpers_path)
    File.chmod(0644, lottie_helpers_path)
    content = File.read(lottie_helpers_path)
    if content.include?('extension Foundation.Bundle: @unchecked Sendable') && !content.include?('// extension Foundation.Bundle: @unchecked Sendable')
      content.gsub!('extension Foundation.Bundle: @unchecked Sendable', '// extension Foundation.Bundle: @unchecked Sendable')
      File.write(lottie_helpers_path, content)
    end
  end
end
