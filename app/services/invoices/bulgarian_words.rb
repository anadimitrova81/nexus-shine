module Invoices
  # Spells out a euro amount in Bulgarian words for the "Словом:" line,
  # e.g. 39123 cents → "Триста деветдесет и един евро и двадесет и три цента".
  module BulgarianWords
    UNITS          = %w[нула един два три четири пет шест седем осем девет].freeze
    UNITS_FEMININE = %w[нула една две три четири пет шест седем осем девет].freeze
    TEENS = %w[десет единадесет дванадесет тринадесет четиринадесет петнадесет
               шестнадесет седемнадесет осемнадесет деветнадесет].freeze
    TENS = [ "", "", "двадесет", "тридесет", "четиридесет", "петдесет",
            "шестдесет", "седемдесет", "осемдесет", "деветдесет" ].freeze
    HUNDREDS = [ "", "сто", "двеста", "триста", "четиристотин", "петстотин",
                "шестстотин", "седемстотин", "осемстотин", "деветстотин" ].freeze

    module_function

    def amount_in_words(total_cents)
      euros, cents = total_cents.to_i.divmod(100)
      words = "#{number_in_words(euros)} евро"
      words += " и #{number_in_words(cents)} #{cents == 1 ? 'цент' : 'цента'}" if cents.positive?
      words.sub(/\A./, &:upcase)
    end

    def number_in_words(number)
      return UNITS[0] if number.zero?
      join_with_and(parts_for(number))
    end

    # Non-zero components in reading order; Bulgarian puts "и" before the last one.
    def parts_for(number)
      millions, rest = number.divmod(1_000_000)
      thousands, rest = rest.divmod(1000)
      parts = []
      parts << (millions == 1 ? "един милион" : "#{join_with_and(parts_for(millions))} милиона") if millions.positive?
      if thousands.positive?
        parts << (thousands == 1 ? "хиляда" : "#{join_with_and(small_parts(thousands, feminine: true))} хиляди")
      end
      parts.concat(small_parts(rest))
    end

    def small_parts(number, feminine: false)
      hundreds, rest = number.divmod(100)
      tens, units = rest.divmod(10)
      parts = []
      parts << HUNDREDS[hundreds] if hundreds.positive?
      if tens == 1
        parts << TEENS[units]
      else
        parts << TENS[tens] if tens.positive?
        parts << (feminine ? UNITS_FEMININE : UNITS)[units] if units.positive?
      end
      parts
    end

    def join_with_and(parts)
      return parts.join(" ") if parts.size < 2
      "#{parts[0..-2].join(' ')} и #{parts.last}"
    end
  end
end
