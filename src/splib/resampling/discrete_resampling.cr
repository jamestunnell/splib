module Splib

# Provide resampling methods (upsampling and downsampling) using
# discrete filtering.
module DiscreteResampling

  def self.upsample(input : Array(Float64), sample_rate : Float64, upsample_factor : Int32, filter_order : Int32)
    raise ArgumentError.new("input.size is less than four") if input.size < 4
    raise ArgumentError.new("upsample_factor is < 2") if  upsample_factor < 2
    verify_positive(sample_rate)

    output = Array(Float64).new((upsample_factor * input.size).to_i, 0.0)
    input.each_index do |i|
      output[i * upsample_factor] = input[i] * upsample_factor
    end

    filter = SincFilter.new(order: filter_order,  sample_rate: sample_rate * upsample_factor,
      cutoff: sample_rate / 2.0, window_class: Window::Nuttall)

    return filter.lowpass(output)
  end

  def self.downsample_input_padding(input_size, downsample_factor)
    npadding_needed = 0
    npast_multiple_of_downsample_factor = input_size % downsample_factor
    if npast_multiple_of_downsample_factor > 0
      npadding_needed = downsample_factor - npast_multiple_of_downsample_factor
    end

    return Array(Float64).new(npadding_needed, 0.0)
  end

  def self.downsample(input : Array(Float64), sample_rate : Float64, downsample_factor : Int32, filter_order : Int32)
    raise ArgumentError.new("input.size is less than four") if input.size < 4
    raise ArgumentError.new("downsample_factor is < 2") if downsample_factor < 1
    verify_positive(sample_rate)

    cutoff = (sample_rate.to_f / downsample_factor) / 2.0
    filter = SincFilter.new(sample_rate: sample_rate, order: filter_order,
      cutoff: cutoff, window_class: Window::Nuttall)

    input += downsample_input_padding(input.size, downsample_factor)
    filtered = filter.lowpass(input)

    output = Array(Float64).new(filtered.size / downsample_factor) do |i|
      filtered[i * downsample_factor]
    end

    return output
  end

  def self.resample(input : Array(Float64), sample_rate : Float64, upsample_factor : Int32, downsample_factor : Int32, filter_order : Int32)
    raise ArgumentError.new("input.size is less than four") if input.size < 4
    raise ArgumentError.new("upsample_factor is < 2") if upsample_factor < 2
    raise ArgumentError.new("downsample_factor is < 2") if downsample_factor < 2
    verify_positive(sample_rate)

    upsampled = Array(Float64).new((upsample_factor * input.size).to_i, 0.0)
    input.each_index do |i|
      upsampled[i * upsample_factor] = input[i] * upsample_factor
    end

    target_rate = sample_rate * upsample_factor / downsample_factor
    cutoff = (target_rate < sample_rate) ? (target_rate / 2.0) : (sample_rate / 2.0)
    filter = SincFilter.new(sample_rate: sample_rate * upsample_factor, order: filter_order,
      cutoff: cutoff, window_class: Window::Nuttall)

    upsampled += downsample_input_padding(upsampled.size, downsample_factor)
    filtered = filter.lowpass(upsampled)

    output = Array.new(filtered.size / downsample_factor) do |i|
      filtered[i * downsample_factor]
    end

    return output
  end
end

end