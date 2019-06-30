# frozen_string_literal: true

require 'rails_helper'

describe 'Test the synchronization between transcript and progenitor' do
  context 'Create a new progenitor' do
    subject { Progenitor.create(name: 'Stark', iq: 180) }

    it { expect { subject }.to change { Transcript.count }.by(1) }

    describe 'The attributes should be transcribed correctly' do
      let(:transcript) { Transcript.find_by(progenitor: subject) }
      it do
        expect(transcript.name).to eq(subject.name)
        expect(transcript.power).to eq(subject.iq * 10_000)
        expect(transcript.job).to eq('Avenger')
      end
    end
  end

  context 'Update a existing progenitor' do
    let!(:progenitor) { Progenitor.create(name: 'Stark', iq: 180) }
    let(:transcript) { Transcript.find_by(progenitor: progenitor) }

    subject { progenitor.update(name: 'Ironman', iq: 200) }

    it { expect { subject }.to change { Transcript.count }.by(0) }

    it 'will change only the attributes that should be changed' do
      subject
      expect(transcript.name).to eq('Ironman')
      expect(transcript.power).to eq(progenitor.iq * 10_000)
      expect(transcript.job).to eq('Avenger')
      expect(transcript.team).to eq('The Avengers')
    end
  end
end

describe 'The association between transcript and progenitor' do
  let!(:progenitor) { Progenitor.create(name: 'Stark') }
  let!(:transcript) { Transcript.find_by(progenitor: progenitor) }

  it { expect(progenitor.transcript).to eq(transcript) }
  it { expect(transcript.progenitor).to eq(progenitor) }
end
