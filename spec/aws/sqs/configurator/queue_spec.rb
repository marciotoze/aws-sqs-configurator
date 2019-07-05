# frozen_string_literal: true

RSpec.describe AWS::SQS::Configurator::Queue, type: :model do
  describe '#initialize' do
    before do
      allow_any_instance_of(described_class).to receive(:account_id).and_return('123456789')
      allow_any_instance_of(AWS::SNS::Configurator::Topic).to receive(:account_id).and_return('123456789')
    end

    subject { described_class.new(options) }

    context 'without name' do
      let(:options) { {} }

      it 'should raise RequiredFieldError' do
        expect { subject }.to raise_error(described_class::RequiredFieldError, 'The field name is required')
      end
    end

    context 'without region' do
      let(:options) { { name: 'update_price' } }

      it 'should raise RequiredFieldError' do
        expect { subject }.to raise_error(described_class::RequiredFieldError, 'The field region is required')
      end
    end

    context 'with just the name' do
      let(:options) { 'update_price' }

      context 'without AWS_REGION environment' do
        it 'should raise RequiredFieldError' do
          expect { subject }.to raise_error(described_class::RequiredFieldError, 'The field region is required')
        end
      end

      context 'with AWS_REGION environment' do
        before { ENV['AWS_REGION'] = 'us-east-1' }

        it 'should have accessors' do
          expect(subject.name).to eq('update_price')
          expect(subject.region).to eq('us-east-1')
          expect(subject.prefix).to be_nil
          expect(subject.suffix).to be_nil
          expect(subject.environment).to be_nil
          expect(subject.metadata).to eq({})
          expect(subject.name_formatted).to eq('update_price')
          expect(subject.arn).to eq('arn:aws:sns:us-east-1:123456789:update_price')
          expect(subject.visibility_timeout).to eq(60)
          expect(subject.max_receive_count).to eq(7)
          expect(subject.message_retention_period).to eq(1_209_600)
          expect(subject.fifo).to be_falsey
          expect(subject.dead_letter_queue).to be_falsey
          expect(subject.dead_letter_queue_suffix).to eq('failures')
          expect(subject.content_based_deduplication).to be_falsey
        end
      end
    end

    context 'without all options' do
      let(:options) do
        {
          name: 'product_updater',
          region: 'sa-east-1',
          prefix: 'system_name',
          suffix: 'queue',
          environment: 'production',
          fifo: true,
          content_based_deduplication: true,
          max_receive_count: 8,
          dead_letter_queue: true,
          dead_letter_queue_suffix: 'errors',
          visibility_timeout: 40,
          message_retention_period: 1_000_000,
          metadata: {
            type: 'strict',
            reference: 'product'
          },
          topics: [
            {
              name: 'product',
              region: 'us-east-1'
            }
          ]
        }
      end

      it 'should have accessors' do
        expect(subject.name).to eq('product_updater')
        expect(subject.region).to eq('sa-east-1')
        expect(subject.prefix).to eq('system_name')
        expect(subject.suffix).to eq('queue')
        expect(subject.environment).to eq('production')
        expect(subject.metadata).to eq(
          type: 'strict',
          reference: 'product'
        )
        expect(subject.name_formatted).to eq('system_name_production_product_updater_queue.fifo')
        expect(subject.arn).to eq('arn:aws:sns:sa-east-1:123456789:system_name_production_product_updater_queue.fifo')
        expect(subject.visibility_timeout).to eq(40)
        expect(subject.max_receive_count).to eq(8)
        expect(subject.message_retention_period).to eq(1_000_000)
        expect(subject.fifo).to be_truthy
        expect(subject.dead_letter_queue).to be_truthy
        expect(subject.dead_letter_queue_suffix).to eq('errors')
        expect(subject.content_based_deduplication).to be_truthy
        expect(subject.topics.all? { |topic| topic.is_a?(AWS::SNS::Configurator::Topic) }).to be_truthy
        expect(subject.topics.length).to eq(1)
        expect(subject.topics.first.name).to eq('product')
        expect(subject.topics.first.name_formatted).to eq('product')
        expect(subject.topics.first.arn).to eq('arn:aws:sns:us-east-1:123456789:product')
      end
    end
  end
end
