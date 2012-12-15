require 'spec_helper'

describe "presets testing:" do
  let(:vim) { VIM }


  PRESETS.each do |test_dir|
    name = File.basename(test_dir)
    specify "#{name}" do
      # read in
      set_file_contents File.read(test_dir + '/in') 
      # apply commands
      apply_commands File.read(test_dir + '/commands')
      # check with out
      assert_file_contents File.read(test_dir + '/out')
    end
  end
end
