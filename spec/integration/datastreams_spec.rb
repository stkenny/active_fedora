require 'spec_helper'

require 'active_fedora'
require 'rexml/document'

describe ActiveFedora::Datastreams do
  describe 'serializing datastreams' do
    before :all do
      class TestingMetadataSerializing < ActiveFedora::Base
        has_metadata :name => 'nokogiri_autocreate_on', :autocreate => true, :type => ActiveFedora::OmDatastream
        has_metadata :name => 'nokogiri_autocreate_off', :autocreate => false, :type => ActiveFedora::OmDatastream
      end
    end

    after :all do
      Object.send(:remove_const, :TestingMetadataSerializing)
    end

    subject { TestingMetadataSerializing.new }

    it 'should work' do
      subject.save(:validate => false)
      expect(subject.nokogiri_autocreate_on).not_to be_new
      expect(subject.nokogiri_autocreate_off).to be_new
    end
  end


  describe '#has_metadata' do
    before :all do
      class HasMetadata < ActiveFedora::Base
        has_metadata :name => 'with_versions', :autocreate => true, :label => 'Versioned DS', :type => ActiveFedora::SimpleDatastream
        has_metadata :name => 'without_versions', :autocreate => true, :versionable => false, :type => ActiveFedora::SimpleDatastream
      end
    end
    after :all do
      Object.send(:remove_const, :HasMetadata)
    end
    before :each do
      @base = ActiveFedora::Base.new(:pid => 'test:has_metadata_base')
      @base.add_datastream(@base.create_datastream(ActiveFedora::Datastream, 'testDS', :dsLabel => 'Test DS'))
      @base.datastreams['testDS'].content = 'blah blah blah'
      @base.save
      @test = HasMetadata.new(:pid => 'test:has_metadata_model')
      @test.save
    end

    after :each do
      @base.delete
      @test.delete
    end

    it 'should create datastreams from the spec on new objects' do
      expect(@test.without_versions.versionable).to be_falsey
      expect(@test.with_versions.versionable).to be_truthy
      expect(@test.with_versions.dsLabel).to eq('Versioned DS')
      @test.without_versions.content = 'blah blah blah'
      @test.save
      expect(HasMetadata.find(@test.pid).without_versions.versionable).to be_falsey
    end

    it 'should use ds_specs and preserve existing datastreams on migrated objects' do
      test_obj = HasMetadata.find(@base.pid)
      expect(test_obj.datastreams['testDS'].dsLabel).to eq('Test DS')
      expect(test_obj.datastreams['testDS'].new?).to be_falsey
      expect(test_obj.with_versions.dsLabel).to eq('Versioned DS')
      expect(test_obj.without_versions.versionable).to be_falsey
      expect(test_obj.with_versions.new?).to be_truthy
    end

  end

  describe '#has_file_datastream' do
    before :all do
      class HasFile < ActiveFedora::Base
        has_file_datastream :name => 'file_ds', :versionable => false
        has_file_datastream :name => 'file_ds2', :versionable => false, :autocreate => false
      end
    end
    after :all do
      Object.send(:remove_const, :HasFile)
    end
    before :each do
      @base = ActiveFedora::Base.new(:pid => 'test:ds_versionable_base')
      @base.save
      @base2 = ActiveFedora::Base.new(:pid => 'test:ds_versionable_base2')
      @base2.add_datastream(@base2.create_datastream(ActiveFedora::Datastream, 'file_ds', :versionable => true, :dsLabel => 'Pre-existing DS'))
      @base2.datastreams['file_ds'].content = 'blah blah blah'
      @base2.save
      @has_file = HasFile.new(:pid => 'test:ds_versionable_has_file')
      @has_file.save
    end

    after :each do
      @base.delete
      @base2.delete
      @has_file.delete
    end

    it 'should create datastreams from the spec on new objects' do
      expect(@has_file.file_ds.versionable).to be_falsey
      @has_file.file_ds.content = 'blah blah blah'
      expect(@has_file.file_ds.changed?).to be_truthy
      expect(@has_file.file_ds2.changed?).to be_falsey # no autocreate
      expect(@has_file.file_ds2.new?).to be_truthy
      @has_file.save
      expect(@has_file.file_ds.versionable).to be_falsey
      test_obj = HasFile.find(@has_file.pid)
      expect(test_obj.file_ds.versionable).to be_falsey
      expect(test_obj.rels_ext.changed?).to be_falsey
      expect(test_obj.file_ds.changed?).to be_falsey
      expect(test_obj.file_ds2.changed?).to be_falsey
      expect(test_obj.file_ds2.new?).to be_truthy
    end

    it 'should use ds_specs on migrated objects' do
      test_obj = HasFile.find(@base.pid)
      expect(test_obj.file_ds.versionable).to be_falsey
      expect(test_obj.file_ds.new?).to be_truthy
      test_obj.file_ds.content = 'blah blah blah'
      test_obj.save
      expect(test_obj.file_ds.versionable).to be_falsey
      # look it up again to check datastream profile
      test_obj = HasFile.find(@base.pid)
      expect(test_obj.file_ds.versionable).to be_falsey
      expect(test_obj.file_ds.dsLabel).to eq('File Datastream')
      test_obj = HasFile.find(@base2.pid)
      expect(test_obj.file_ds.versionable).to be_truthy
      expect(test_obj.file_ds.dsLabel).to eq('Pre-existing DS')
    end
  end
end
