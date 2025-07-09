require "./spec_helper"

describe Opusenc::Encoder do
  it "encodes a wav file" do
    output_filename = "test.opus"
    begin
      # Generate a sine wave
      sample_rate = 48000
      channels = 1
      duration = 1
      frequency = 440
      volume = 16000
      num_samples = sample_rate * duration
      samples = Slice(Int16).new(num_samples * channels)
      (0...num_samples).each do |i|
        samples[i] = (Math.sin(2 * Math::PI * frequency * i / sample_rate) * volume).to_i16
      end

      # Encode the file
      encoder = Opusenc::Encoder.new(output_filename, sample_rate, channels)
      encoder.write(samples)
      encoder.close

      # Check if the output file exists and is not empty
      File.exists?(output_filename).should be_true
      File.size(output_filename).should be > 0
    ensure
      File.delete(output_filename) if File.exists?(output_filename)
    end
  end
end
