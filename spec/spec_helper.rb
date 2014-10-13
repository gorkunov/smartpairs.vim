require 'tmpdir'
require 'vimrunner'
require_relative './support/vim'

PRESETS = Dir.glob([File.expand_path('.'), 'spec/tests', '**'].join('/')).sort

module VIM
  extend self
  attr_accessor :instance
end
RSpec.configure do |config|
  config.include Support::Vim

  # cd into a temporary directory for every example.
  config.around do |example|
    VIM.instance = Vimrunner.start
    VIM.instance.add_plugin(File.expand_path('.'), 'spec/support/settings.vim')
    VIM.instance.add_plugin(File.expand_path('.'), 'plugin/smartpairs.vim')
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        VIM.instance.command("cd #{dir}")
        example.call
      end
    end
    VIM.instance.kill
  end
end
