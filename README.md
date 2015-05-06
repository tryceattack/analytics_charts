# AnalyticsCharts

Custom library for a pie chart. Originated from the gruff library, but branched out.

## Installation

Add this line to your application's Gemfile:

    gem 'analytics_charts'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install analytics_charts

## Usage

#!/usr/bin/env ruby
require 'analytics-charts'
g = AnalyticsCharts::CustomPie.new('./yourImage.png')
hash = {
      'fill' => 'blue',
      'font_family' => 'Helvetica',
      'pointsize' => 64,
      'font_weight' => 700
    }

g.set_pie_geometry(1242,620, 250)
g.insert_pie_data("ndaf me3", 15.1,1)
g.insert_pie_data("ndaf me4", 15,3)
g.insert_pie_data("ndaf me2", 15.7,2)
g.insert_pie_data("ndaf me1", 300.22,0)
g.write

## Contributing

1. Fork it ( http://github.com/tryceattack/analytics_charts/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
