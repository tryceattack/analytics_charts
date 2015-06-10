require 'analytics_charts/version'

%w(
  custom_pie
  custom_module
).each do |filename|
  require "analytics_charts/#{filename}"
end
