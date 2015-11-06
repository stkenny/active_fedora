require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class ValidationStub < ActiveFedora::Base
      has_metadata :type => ActiveFedora::SimpleDatastream, :name => 'someData' do |m|
        m.field 'fubar', :string
        m.field 'swank', :text
      end
      delegate :fubar, :to => 'someData', multiple: true
      delegate :swank, :to => 'someData', multiple: false

      validates_presence_of :fubar
      validates_length_of :swank, :minimum => 5

    end
  end

  subject { ValidationStub.new }

  after :all do
    Object.send(:remove_const, :ValidationStub)
  end

  describe 'a valid object' do
    before do
      subject.attributes = { fubar: 'here', swank: 'long enough'}
    end

    it { is_expected.to be_valid}
  end
  describe 'an invalid object' do
    before do
      subject.attributes = { swank: 'smal'}
    end
    it 'should have errors' do
      expect(subject).not_to be_valid
      expect(subject.errors[:fubar]).to eq(["can't be blank"])
      expect(subject.errors[:swank]).to eq(['is too short (minimum is 5 characters)'])
    end
  end

  describe 'required terms' do
    it 'should be required' do
       expect(subject.required?(:fubar)).to be_truthy
       expect(subject.required?(:swank)).to be_falsey
    end
  end

end
