require 'analytics_charts/version'

%w(
  custom_pie
).each do |filename|
  require "analytics_charts/#{filename}"
end
