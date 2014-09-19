# setup environment for running cookbook tests
# This recipe uses "minitest-chef-handler" to facilitate cookbook testing.
# minitest-chef-handler project: https://github.com/calavera/minitest-chef-handler

if node[:opsworks][:run_cookbook_tests]
  Chef::Log.info('Initializing Cookbook Test Environment.')

  chef_gem 'minitest-chef-handler' do
    version node[:test_suite][:minitest_chef_handler][:version]
  end

  require 'minitest-chef-handler'

  merged_cookbooks_path = Opsworks::InstanceAgent::Environment.merged_cookbooks_path
  specs = run_context.loaded_recipes.map do |loaded_recipe|
    cookbook, recipe = loaded_recipe.split('::')
    recipe ||= 'default'
    ::File.join(merged_cookbooks_path, cookbook, 'specs/**', "#{recipe}_spec.rb")
  end

  Chef::Log.info('Enabling minitest-chef-handler as a report handler')
  handler = MiniTest::Chef::Handler.new(
    :path => specs,
    :verbose => true
  )

  Chef::Config.send('report_handlers').delete_if do |v|
    v.class.to_s.include? MiniTest::Chef::Handler
  end

  Chef::Config.send('report_handlers') << handler

  # trigger internal tests, that don't have specs but recipes
  include_recipe 'test_suite::internal_tests'
end
