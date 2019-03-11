require 'pry-jist'
require 'rspec'

RSpec.configure do |c|
  c.order = 'random'
  c.color = true
  c.disable_monkey_patching!
end
