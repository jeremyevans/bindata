require "bindata/single"

module BinData
  # A String is a sequence of bytes.  This is the same as strings in Ruby.
  # The issue of character encoding is ignored by this class.
  #
  #   require 'bindata'
  #
  #   data = "abcdefghij"
  #
  #   obj = BinData::String.new(:read_length => 5)
  #   obj.read(data)
  #   obj.value #=> "abcde"
  #
  #   obj = BinData::String.new(:length => 6)
  #   obj.read(data)
  #   obj.value #=> "abcdef"
  #   obj.value = "abcdefghij"
  #   obj.value #=> "abcdef"
  #   obj.value = "abcd"
  #   obj.value #=> "abcd\000\000"
  #
  #   obj = BinData::String.new(:length => 6, :trim_value => true)
  #   obj.value = "abcd"
  #   obj.value #=> "abcd"
  #   obj.to_s #=> "abcd\000\000"
  #
  #   obj = BinData::String.new(:length => 6, :pad_char => 'A')
  #   obj.value = "abcd"
  #   obj.value #=> "abcdAA"
  #   obj.to_s #=> "abcdAA"
  #
  # == Parameters
  #
  # String objects accept all the params that BinData::Single
  # does, as well as the following:
  #
  # <tt>:read_length</tt>::    The length to use when reading a value.
  # <tt>:length</tt>::         The fixed length of the string.  If a shorter
  #                            string is set, it will be padded to this length.
  # <tt>:pad_char</tt>::       The character to use when padding a string to a
  #                            set length.  Valid values are Integers and
  #                            Strings of length 1.  "\0" is the default.
  # <tt>:trim_value</tt>::     Boolean, default false.  If set, #value will
  #                            return the value with all pad_chars trimmed
  #                            from the end of the string.  The value will
  #                            not be trimmed when writing.
  class String < BinData::Single

    # Register this class
    register(self.name, self)

    # These are the parameters used by this class.
    optional_parameters  :read_length, :length, :trim_value
    default_parameters   :pad_char => "\0"
    mutually_exclusive_parameters :read_length, :length
    mutually_exclusive_parameters :length, :value

    class << self

      # Returns a sanitized +params+ that is of the form expected
      # by #initialize.
      def sanitize_parameters(sanitizer, params)
        new_params = params.dup

        # warn about deprecated param - remove before releasing 1.0
        if new_params[:initial_length]
          warn ":initial_length is deprecated. Replacing with :read_length"
          new_params[:read_length] = new_params.delete(:initial_length)
        end

        # set :pad_char to be a single length character string
        if new_params.has_key?(:pad_char)
          ch = new_params[:pad_char]
          ch = ch.respond_to?(:chr) ? ch.chr : ch.to_s
          if ch.length > 1
            raise ArgumentError, ":pad_char must not contain more than 1 char"
          end
          new_params[:pad_char] = ch
        end

        super(sanitizer, new_params)
      end
    end

    # Overrides value to return the value padded to the desired length or
    # trimmed as required.
    def value
      v = val_to_str(_value)
      v.sub!(/#{eval_param(:pad_char)}*$/, "") if param(:trim_value) == true
      v
    end

    #---------------
    private

    # Returns +val+ ensuring that it is padded to the desired length.
    def val_to_str(val)
      # trim val if necessary
      len = eval_param(:length) || val.length
      str = val.slice(0, len)

      # then pad to length if str is short
      str << (eval_param(:pad_char) * (len - str.length))
    end

    # Read a number of bytes from +io+ and return the value they represent.
    def read_val(io)
      len = eval_param(:read_length) || eval_param(:length) || 0
      io.readbytes(len)
    end

    # Returns an empty string as default.
    def sensible_default
      ""
    end
  end
end
