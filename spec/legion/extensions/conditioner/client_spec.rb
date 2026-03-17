# frozen_string_literal: true

require 'spec_helper'
require 'legion/json'
require 'legion/extensions/conditioner/client'

RSpec.describe Legion::Extensions::Conditioner::Client do
  subject(:client) { described_class.new }

  describe '#evaluate' do
    context 'with passing conditions (hash input)' do
      it 'returns valid: true' do
        result = client.evaluate(
          conditions: { all: [{ fact: 'status', operator: 'equal', value: 200 }] },
          values:     { status: 200 }
        )
        expect(result[:valid]).to eq(true)
      end
    end

    context 'with failing conditions' do
      it 'returns valid: false' do
        result = client.evaluate(
          conditions: { all: [{ fact: 'status', operator: 'equal', value: 404 }] },
          values:     { status: 200 }
        )
        expect(result[:valid]).to eq(false)
      end
    end

    context 'explanation hash' do
      it 'includes explanation with rules array' do
        result = client.evaluate(
          conditions: { all: [{ fact: 'name', operator: 'equal', value: 'legion' }] },
          values:     { name: 'legion' }
        )
        expect(result[:explanation]).to be_a(Hash)
        expect(result[:explanation][:rules]).to be_an(Array)
        expect(result[:explanation][:rules]).not_to be_empty
      end
    end

    context 'with string conditions (pre-serialized JSON)' do
      it 'accepts a JSON string directly' do
        json_conditions = Legion::JSON.dump({ all: [{ fact: 'env', operator: 'equal', value: 'production' }] })
        result = client.evaluate(
          conditions: json_conditions,
          values:     { env: 'production' }
        )
        expect(result[:valid]).to eq(true)
      end
    end

    context 'with numeric operators' do
      it 'works with greater_or_equal and less_than combo' do
        result = client.evaluate(
          conditions: { all: [
            { fact: 'score', operator: 'greater_or_equal', value: 50 },
            { fact: 'score', operator: 'less_than', value: 100 }
          ] },
          values:     { score: 75 }
        )
        expect(result[:valid]).to eq(true)
      end
    end

    context 'with string operators' do
      it 'works with contains' do
        result = client.evaluate(
          conditions: { all: [{ fact: 'message', operator: 'contains', value: 'error' }] },
          values:     { message: 'critical error occurred' }
        )
        expect(result[:valid]).to eq(true)
      end
    end

    context 'with collection operators' do
      it 'works with in_set' do
        result = client.evaluate(
          conditions: { all: [{ fact: 'env', operator: 'in_set', value: %w[staging production] }] },
          values:     { env: 'staging' }
        )
        expect(result[:valid]).to eq(true)
      end
    end

    context 'with nested values via dot notation' do
      it 'evaluates against dotted-path facts' do
        result = client.evaluate(
          conditions: { all: [{ fact: 'response.code', operator: 'equal', value: 200 }] },
          values:     { response: { code: 200 } }
        )
        expect(result[:valid]).to eq(true)
      end
    end

    context 'with complex nested conditions (any containing all groups)' do
      it 'evaluates correctly' do
        result = client.evaluate(
          conditions: { any: [
            { all: [
              { fact: 'a', operator: 'equal', value: 1 },
              { fact: 'b', operator: 'equal', value: 2 }
            ] },
            { all: [
              { fact: 'c', operator: 'equal', value: 3 },
              { fact: 'd', operator: 'equal', value: 4 }
            ] }
          ] },
          values:     { a: 1, b: 2, c: 99, d: 99 }
        )
        expect(result[:valid]).to eq(true)
      end
    end

    context 'explanation on failure' do
      it 'includes actual values' do
        result = client.evaluate(
          conditions: { all: [{ fact: 'status', operator: 'equal', value: 404 }] },
          values:     { status: 200 }
        )
        rule = result[:explanation][:rules].first
        expect(rule[:actual]).to eq(200)
        expect(rule[:result]).to eq(false)
      end
    end
  end
end
