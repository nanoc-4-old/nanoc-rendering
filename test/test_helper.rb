# encoding: utf-8

require 'helper'

class Nanoc::Rendering::HelperTest < Minitest::Test

  include Nanoc::Rendering::Helper

  def setup
    @_orig_wd = Dir.getwd

    FileUtils.mkdir_p('_site')
    FileUtils.cd('_site')

    File.write('nanoc.yaml', '{}')
    FileUtils.mkdir_p('content')
    FileUtils.mkdir_p('layouts')
    FileUtils.mkdir_p('lib')
    FileUtils.mkdir_p('output')
  end

  def teardown
    FileUtils.cd(@_orig_wd)
    FileUtils.rm_rf('_site')
  end

  def site_here
    Nanoc::SiteLoader.new.load
  end

  def in_site
    yield
  end

  def test_render
    in_site do
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo', :erb\n")
      end
      File.open('layouts/foo', 'w') do |io|
        io.write 'This is the <%= @layout.identifier %> layout.'
      end

      @site = site_here
      @_compiler = Nanoc::Compiler.new(@site)
      @_compiler.load
      assert_equal('This is the /foo layout.', render('/foo'))
    end
  end

  def test_render_with_unknown_layout
    in_site do
      @site = site_here
      assert_raises(Nanoc::Errors::UnknownLayout) do
        render '/dsfghjkl'
      end
    end
  end

  def test_render_without_filter
    in_site do
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo', nil\n")
      end
      File.open('layouts/foo', 'w')

      @site = site_here
      @_compiler = Nanoc::Compiler.new(@site)
      @_compiler.load
      assert_raises(Nanoc::Errors::CannotDetermineFilter) do
        render '/foo'
      end
    end
  end

  def test_render_with_unknown_filter
    in_site do
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo', :asdf\n")
      end
      File.open('layouts/foo', 'w')

      @site = site_here
      @_compiler = Nanoc::Compiler.new(@site)
      @_compiler.load
      assert_raises(Nanoc::Errors::UnknownFilter) do
        render '/foo'
      end
    end
  end

  def test_render_with_block
    in_site do
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo', :erb\n")
      end
      File.open('layouts/foo', 'w') do |io|
        io.write '[partial-before]<%= yield %>[partial-after]'
      end

      @site = site_here
      @_compiler = Nanoc::Compiler.new(@site)
      @_compiler.load

      _erbout = '[erbout-before]'
      result = render '/foo' do
        _erbout << "This is some extra content"
      end

      assert_equal('[erbout-before][partial-before]This is some extra content[partial-after]', _erbout)
      assert_equal '', result
    end
  end

end
