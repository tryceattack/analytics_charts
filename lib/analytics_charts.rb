require 'analytics_charts/version'

%w(
  custom_pie
  custom_module
  pie_and_labels
).each do |filename|
  require "analytics_charts/#{filename}"
end
