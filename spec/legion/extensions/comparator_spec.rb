# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/helpers/comparator'

RSpec.describe Legion::Extensions::Conditioner::Comparator do
  let(:values) { { 'status' => 200, 'name' => 'test', 'items' => [1, 2], 'flag' => true, 'empty' => nil, 'count' => 5 } }

  describe '.equal?' do
    it 'returns true when fact matches value' do
      expect(described_class.equal?('status', 200, values)).to eq(true)
    end

    it 'returns false when fact does not match' do
      expect(described_class.equal?('status', 404, values)).to eq(false)
    end

    it 'handles string comparison' do
      expect(described_class.equal?('name', 'test', values)).to eq(true)
    end
  end

  describe '.not_equal?' do
    it 'returns true when fact does not match value' do
      expect(described_class.not_equal?('status', 404, values)).to eq(true)
    end

    it 'returns false when fact matches' do
      expect(described_class.not_equal?('status', 200, values)).to eq(false)
    end
  end

  describe '.nil?' do
    it 'returns true when fact is nil' do
      expect(described_class.nil?('empty', values)).to eq(true)
    end

    it 'returns true when fact does not exist' do
      expect(described_class.nil?('nonexistent', values)).to eq(true)
    end

    it 'returns false when fact has a value' do
      expect(described_class.nil?('name', values)).to eq(false)
    end
  end

  describe '.not_nil?' do
    it 'returns true when fact has a value' do
      expect(described_class.not_nil?('name', values)).to eq(true)
    end

    it 'returns false when fact is nil' do
      expect(described_class.not_nil?('empty', values)).to eq(false)
    end
  end

  describe '.true?' do
    it 'returns truthy when fact is true' do
      expect(described_class.true?('flag', values)).to be_truthy
    end

    it 'returns falsey when fact is nil' do
      expect(described_class.true?('empty', values)).to be_falsey
    end
  end

  describe '.false?' do
    it 'returns true when fact is falsey' do
      expect(described_class.false?('empty', values)).to eq(true)
    end

    it 'returns nil when fact is truthy' do
      expect(described_class.false?('flag', values)).to be_nil
    end
  end

  describe '.array?' do
    it 'returns true when fact is an array' do
      expect(described_class.array?('items', values)).to eq(true)
    end

    it 'returns false when fact is not an array' do
      expect(described_class.array?('name', values)).to eq(false)
    end
  end

  describe '.string?' do
    it 'returns true when fact is a string' do
      expect(described_class.string?('name', values)).to eq(true)
    end

    it 'returns false when fact is not a string' do
      expect(described_class.string?('status', values)).to eq(false)
    end
  end

  describe '.integer?' do
    it 'returns true when fact is an integer' do
      expect(described_class.integer?('count', values)).to eq(true)
    end

    it 'returns false when fact is not an integer' do
      expect(described_class.integer?('name', values)).to eq(false)
    end
  end
end
