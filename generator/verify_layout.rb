# frozen_string_literal: true

require_relative "../lib/jolt/native/generated"

probe = ARGV.fetch(0)
actual_sizes = {}
actual_offsets = Hash.new { |hash, key| hash[key] = {} }

IO.foreach(probe) do |line|
  kind, struct_name, field_name, value = line.chomp.split("\t")
  if kind == "S"
    actual_sizes[struct_name] = Integer(field_name)
  else
    actual_offsets[struct_name][field_name.to_sym] = Integer(value)
  end
end

failures = Jolt::Native::Generated::HEADER_LAYOUTS.filter_map do |name, (expected_size, expected_offsets)|
  klass = Jolt::Native::Generated.const_get(name.delete_prefix("JPH_"))
  ruby_offsets = expected_offsets.to_h { |field, _offset| [field, klass.offset_of(field)] }
  next if actual_sizes[name] == expected_size &&
          klass.size == expected_size &&
          actual_offsets[name] == expected_offsets &&
          ruby_offsets == expected_offsets

  "#{name}: C=#{[actual_sizes[name], actual_offsets[name]].inspect} " \
    "Clang=#{[expected_size, expected_offsets].inspect} " \
    "FFI=#{[klass.size, ruby_offsets].inspect}"
end

abort "FFI layout mismatch:\n#{failures.join("\n")}" unless failures.empty?
puts "Verified #{Jolt::Native::Generated::HEADER_LAYOUTS.length} FFI struct layouts"
