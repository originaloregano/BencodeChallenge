require 'stringio'

class Parser
  def decode_bencode(string)
    parse(string)
  end

  def parse(string)
    case string[0]
    when 'i'
      parse_integer(string)
    when 'l'
      parse_list(string)
    when 'd'
      parse_map(string)
    end
  end

  def parse_integer(string)
    if is_integer?(string)
      string[1..-2].to_i
    end
  end

  def is_integer?(string)
    string[0] == 'i' && string[-1] == 'e'
  end

  def parse_list(string)
    if string.is_a?(StringIO)
      str = string
      str.getc if peek(str) == 'l'
    elsif is_list?(string)
      str = StringIO.new string[1..-2]
    end
    parse_io_list(str)
  end

  def peek(str)
    char = str.getc
    str.ungetc(char)
    char
  end

  def is_list?(string)
    string[0] == 'l' && string[-1] == 'e'
  end

  def parse_map(string)
    if string.is_a?(StringIO)
      string.getc if peek(string) == 'd'
      list_of_keys_and_values = parse_list(string)
    elsif is_dictionary?(string)
      list_of_keys_and_values = parse_list("l#{ string[1..-2] }e")
    end
    convert_to_hash(list_of_keys_and_values)
  end

  def convert_to_hash(list)
    hash = {}
    list.each_slice(2) {|k,v| hash[k] = v }
    hash
  end

  def is_dictionary?(string)
    string[0] == 'd' && string[-1] == 'e'
  end

  def parse_io_list(str)
    list = []
    until peek(str) == 'e' || str.eof?
      case peek(str)
      when 'i'
        list << parse_integer(str.gets(sep='e'))
      when 'l'
        list << parse_list(str)
      when 'd'
        list << parse_map(str)
      when grab_first_int_of_dict
        length = length_of_words_in_dictionary(str)
        list << str.gets(length)
      end
    end
    str.getc
    list
  end
end

def grab_first_int_of_dict
  lambda {|d| d.scan(/\d/) }
end

def length_of_words_in_dictionary(str)
  str.gets(sep=':').to_i
end

p = Parser.new
p p.decode_bencode("i10e") # == 10
p p.decode_bencode("le") # == []
p p.decode_bencode("li10ee") # == [10]
p p.decode_bencode("li10ei15ee") # == [10,15]
p p.decode_bencode("lleli8eee") # == [[],[8]]
p p.decode_bencode("lleleli8eee") # == [[],[],[8]]
p p.decode_bencode("l4:star3:foxe") # == ["star", "fox"]
p p.decode_bencode("d3:bar4:spam3:fooi42ee") # == {"bar": "spam", "foo": 42}
