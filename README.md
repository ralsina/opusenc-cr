# opusenc

A Crystal wrapper for the `libopusenc` library, providing high-level bindings for Opus audio encoding.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     opusenc-cr:
       github: ralsina/opusenc-cr
   ```

2. Run `shards install`

## Usage

```crystal
require "opusenc"

# Example: Encode a sine wave to an Opus file
sample_rate = 48000
channels = 1
duration = 1 # seconds
frequency = 440 # Hz
volume = 16000 # Max 32767 for Int16

num_samples = sample_rate * duration
samples = Slice(Int16).new(num_samples * channels)

(0...num_samples).each do |i|
  samples[i] = (Math.sin(2 * Math::PI * frequency * i / sample_rate) * volume).to_i16
end

output_filename = "output.opus"
encoder = Opusenc::Encoder.new(output_filename, sample_rate, channels)
encoder.write(samples)
encoder.close

puts "Encoded sine wave to #{output_filename}"
```

## Example CLI Usage

To convert a WAV file to Opus:

```bash
crystal run examples/cli.cr -i input.wav -o output.opus -s 48000 -c 1
```

Arguments:
*   `-i INPUT`: Path to the input WAV file.
*   `-o OUTPUT`: Path to the output Opus file.
*   `-s SAMPLE_RATE`: Sample rate of the audio (default: 48000).
*   `-c CHANNELS`: Number of audio channels (default: 1).

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/ralsina/opusenc/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Roberto Alsina](https://github.com/ralsina) - creator and maintainer
