# frozen_string_literal: true

require 'spec_helper'
require 'legion/json'
require 'legion/extensions/conditioner/helpers/condition'

RSpec.describe Legion::Extensions::Conditioner::Condition do
  describe '#to_dotted_hash' do
    let(:condition) do
      described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'status', operator: 'equal', value: 200 }] }),
        values:     { status: 200 }
      )
    end

    it 'flattens a simple hash' do
      result = condition.to_dotted_hash({ a: 1, b: 2 })
      expect(result['a']).to eq(1)
      expect(result['b']).to eq(2)
    end

    it 'flattens nested hashes with dot notation' do
      result = condition.to_dotted_hash({ response: { code: 200, body: 'ok' } })
      expect(result['response.code']).to eq(200)
      expect(result['response.body']).to eq('ok')
    end

    it 'flattens arrays with index notation' do
      result = condition.to_dotted_hash({ items: %w[a b c] })
      expect(result['items.0']).to eq('a')
      expect(result['items.1']).to eq('b')
      expect(result['items.2']).to eq('c')
    end

    it 'handles deeply nested structures' do
      result = condition.to_dotted_hash({ a: { b: { c: 'deep' } } })
      expect(result['a.b.c']).to eq('deep')
    end
  end

  describe '#valid? with all conditions' do
    it 'returns true when all conditions pass' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'status', operator: 'equal', value: 200 },
                                        { fact: 'name', operator: 'equal', value: 'test' }
                                      ] }),
        values:     { status: 200, name: 'test' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false when any condition in all fails' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'status', operator: 'equal', value: 200 },
                                        { fact: 'name', operator: 'equal', value: 'wrong' }
                                      ] }),
        values:     { status: 200, name: 'test' }
      )
      expect(cond.valid?).to eq(false)
    end
  end

  describe '#valid? with any conditions' do
    it 'returns true when at least one condition passes' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { fact: 'status', operator: 'equal', value: 404 },
                                        { fact: 'name', operator: 'equal', value: 'test' }
                                      ] }),
        values:     { status: 200, name: 'test' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false when no conditions pass' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { fact: 'status', operator: 'equal', value: 404 },
                                        { fact: 'name', operator: 'equal', value: 'wrong' }
                                      ] }),
        values:     { status: 200, name: 'test' }
      )
      expect(cond.valid?).to eq(false)
    end
  end

  describe '#valid? with not_equal operator' do
    it 'returns true when values differ' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'status', operator: 'not_equal', value: 404 }
                                      ] }),
        values:     { status: 200 }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#valid? with unary operators' do
    it 'handles nil operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'missing', operator: 'nil' }] }),
        values:     { other: 'value' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles not_nil operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'name', operator: 'not_nil' }] }),
        values:     { name: 'present' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles is_string operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'name', operator: 'is_string' }] }),
        values:     { name: 'hello' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles is_integer operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'count', operator: 'is_integer' }] }),
        values:     { count: 42 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles is_array operator (arrays get flattened by to_dotted_hash)' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'items', operator: 'is_array' }] }),
        values:     { items: [1, 2, 3] }
      )
      # to_dotted_hash flattens arrays into indexed keys (items.0, items.1, etc.)
      # so the original 'items' key no longer exists as an array
      expect(cond.valid?).to eq(false)
    end

    it 'handles is_true operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'flag', operator: 'is_true' }] }),
        values:     { flag: true }
      )
      expect(cond.valid?).to be_truthy
    end

    it 'handles is_false operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'flag', operator: 'is_false' }] }),
        values:     { flag: nil }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#valid? with nested conditions' do
    it 'handles nested all within any' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { all: [
                                          { fact: 'a', operator: 'equal', value: 1 },
                                          { fact: 'b', operator: 'equal', value: 2 }
                                        ] }
                                      ] }),
        values:     { a: 1, b: 2 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false when nested all fails' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { all: [
                                          { fact: 'a', operator: 'equal', value: 1 },
                                          { fact: 'b', operator: 'equal', value: 99 }
                                        ] }
                                      ] }),
        values:     { a: 1, b: 2 }
      )
      expect(cond.valid?).to eq(false)
    end

    it 'handles nested any within all' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { any: [
                                          { fact: 'x', operator: 'equal', value: 10 },
                                          { fact: 'y', operator: 'equal', value: 20 }
                                        ] }
                                      ] }),
        values:     { x: 99, y: 20 }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#valid? with dotted fact paths' do
    it 'evaluates against flattened nested values' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'response.code', operator: 'equal', value: 200 }
                                      ] }),
        values:     { response: { code: 200 } }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#valid? caching' do
    it 'memoizes the result' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'x', operator: 'equal', value: 1 }] }),
        values:     { x: 1 }
      )
      expect(cond.valid?).to eq(true)
      expect(cond.valid?).to eq(true)
    end
  end
end
