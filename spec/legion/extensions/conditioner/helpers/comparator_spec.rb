# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/helpers/comparator'

RSpec.describe Legion::Extensions::Conditioner::Comparator do
  let(:values) do
    {
      'status'   => 200,
      'count'    => 5,
      'zero'     => 0,
      'name'     => 'test',
      'greeting' => 'hello world',
      'blank'    => '',
      'items'    => [1, 2],
      'tags'     => %w[bug feature],
      'flag'     => true,
      'empty'    => nil
    }
  end

  # ── Existing operators ────────────────────────────────────────────────────

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

    it 'returns false when fact is truthy' do
      expect(described_class.false?('flag', values)).to eq(false)
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

  # ── Numeric operators ─────────────────────────────────────────────────────

  describe '.greater_than?' do
    it 'returns true when fact is greater than value' do
      expect(described_class.greater_than?('status', 100, values)).to eq(true)
    end

    it 'returns false when fact equals value' do
      expect(described_class.greater_than?('status', 200, values)).to eq(false)
    end

    it 'returns false when fact is less than value' do
      expect(described_class.greater_than?('count', 10, values)).to eq(false)
    end
  end

  describe '.less_than?' do
    it 'returns true when fact is less than value' do
      expect(described_class.less_than?('count', 10, values)).to eq(true)
    end

    it 'returns false when fact equals value' do
      expect(described_class.less_than?('count', 5, values)).to eq(false)
    end

    it 'returns false when fact is greater than value' do
      expect(described_class.less_than?('status', 100, values)).to eq(false)
    end
  end

  describe '.greater_or_equal?' do
    it 'returns true when fact equals value' do
      expect(described_class.greater_or_equal?('status', 200, values)).to eq(true)
    end

    it 'returns true when fact is greater than value' do
      expect(described_class.greater_or_equal?('status', 100, values)).to eq(true)
    end

    it 'returns false when fact is less than value' do
      expect(described_class.greater_or_equal?('count', 10, values)).to eq(false)
    end
  end

  describe '.less_or_equal?' do
    it 'returns true when fact equals value' do
      expect(described_class.less_or_equal?('count', 5, values)).to eq(true)
    end

    it 'returns true when fact is less than value' do
      expect(described_class.less_or_equal?('count', 10, values)).to eq(true)
    end

    it 'returns false when fact is greater than value' do
      expect(described_class.less_or_equal?('status', 100, values)).to eq(false)
    end
  end

  describe '.between?' do
    it 'returns true when fact is within inclusive range' do
      expect(described_class.between?('status', [100, 300], values)).to eq(true)
    end

    it 'returns true when fact equals lower bound' do
      expect(described_class.between?('status', [200, 300], values)).to eq(true)
    end

    it 'returns true when fact equals upper bound' do
      expect(described_class.between?('status', [100, 200], values)).to eq(true)
    end

    it 'returns false when fact is below range' do
      expect(described_class.between?('count', [10, 20], values)).to eq(false)
    end

    it 'returns false when fact is above range' do
      expect(described_class.between?('count', [0, 4], values)).to eq(false)
    end
  end

  # ── String operators ──────────────────────────────────────────────────────

  describe '.contains?' do
    it 'returns true when string contains substring' do
      expect(described_class.contains?('greeting', 'hello', values)).to eq(true)
    end

    it 'returns false when string does not contain substring' do
      expect(described_class.contains?('greeting', 'bye', values)).to eq(false)
    end

    it 'coerces fact to string' do
      expect(described_class.contains?('status', '20', values)).to eq(true)
    end
  end

  describe '.starts_with?' do
    it 'returns true when string starts with prefix' do
      expect(described_class.starts_with?('greeting', 'hello', values)).to eq(true)
    end

    it 'returns false when string does not start with prefix' do
      expect(described_class.starts_with?('greeting', 'world', values)).to eq(false)
    end

    it 'coerces fact to string' do
      expect(described_class.starts_with?('status', '2', values)).to eq(true)
    end
  end

  describe '.ends_with?' do
    it 'returns true when string ends with suffix' do
      expect(described_class.ends_with?('greeting', 'world', values)).to eq(true)
    end

    it 'returns false when string does not end with suffix' do
      expect(described_class.ends_with?('greeting', 'hello', values)).to eq(false)
    end

    it 'coerces fact to string' do
      expect(described_class.ends_with?('status', '00', values)).to eq(true)
    end
  end

  describe '.matches?' do
    it 'returns true when fact matches regex pattern' do
      expect(described_class.matches?('greeting', 'hello.*world', values)).to eq(true)
    end

    it 'returns false when fact does not match regex pattern' do
      expect(described_class.matches?('greeting', '^world', values)).to eq(false)
    end

    it 'handles digit patterns' do
      expect(described_class.matches?('status', '^\d+$', values)).to eq(true)
    end
  end

  # ── Collection operators ──────────────────────────────────────────────────

  describe '.in_set?' do
    it 'returns true when fact is in the array value' do
      expect(described_class.in_set?('status', [200, 201, 204], values)).to eq(true)
    end

    it 'returns false when fact is not in the array value' do
      expect(described_class.in_set?('status', [400, 404, 500], values)).to eq(false)
    end

    it 'wraps scalar value in array' do
      expect(described_class.in_set?('status', 200, values)).to eq(true)
    end
  end

  describe '.not_in_set?' do
    it 'returns true when fact is not in the array value' do
      expect(described_class.not_in_set?('status', [400, 404, 500], values)).to eq(true)
    end

    it 'returns false when fact is in the array value' do
      expect(described_class.not_in_set?('status', [200, 201], values)).to eq(false)
    end

    it 'wraps scalar value in array' do
      expect(described_class.not_in_set?('status', 404, values)).to eq(true)
    end
  end

  describe '.empty?' do
    it 'returns true when fact is nil' do
      expect(described_class.empty?('empty', values)).to eq(true)
    end

    it 'returns true when fact is a blank string' do
      expect(described_class.empty?('blank', values)).to eq(true)
    end

    it 'returns false when fact is a non-empty string' do
      expect(described_class.empty?('name', values)).to eq(false)
    end

    it 'returns false when fact is a non-empty array' do
      expect(described_class.empty?('items', values)).to eq(false)
    end

    it 'returns true when fact is an empty array' do
      vals = values.merge('arr' => [])
      expect(described_class.empty?('arr', vals)).to eq(true)
    end
  end

  describe '.not_empty?' do
    it 'returns true when fact is a non-empty string' do
      expect(described_class.not_empty?('name', values)).to eq(true)
    end

    it 'returns true when fact is a non-empty array' do
      expect(described_class.not_empty?('items', values)).to eq(true)
    end

    it 'returns false when fact is nil' do
      expect(described_class.not_empty?('empty', values)).to eq(false)
    end

    it 'returns false when fact is a blank string' do
      expect(described_class.not_empty?('blank', values)).to eq(false)
    end
  end

  describe '.size_equal?' do
    it 'returns true when array size matches value' do
      expect(described_class.size_equal?('items', 2, values)).to eq(true)
    end

    it 'returns false when array size does not match' do
      expect(described_class.size_equal?('items', 5, values)).to eq(false)
    end

    it 'returns true when string length matches value' do
      expect(described_class.size_equal?('name', 4, values)).to eq(true)
    end

    it 'returns false when object does not respond to size' do
      expect(described_class.size_equal?('status', 3, values)).to eq(false)
    end
  end
end
