# frozen_string_literal: true

# Constants to configure holidays that
# will be calculated for a given year.

class Holidays
  HOLIDAYS_FIXED = [
    [1, 1, 'Neujahr'],
    [1, 2, 'Berchtoldstag'],
    [8, 1, 'Bundesfeiertag'],
    [12, 25, 'Weihnachten'],
    [12, 26, 'Stefanstag']
  ].freeze

  HOLIDAYS_RELATIVE_TO_EASTER = [
    [-2, 'Karfreitag'],
    [0, 'Ostersonntag'],
    [1, 'Ostermontag'],
    [39, 'Auffahrt'],
    [49, 'Pfingstsonntag'],
    [50, 'Pfingstmontag']
  ].freeze

  def dates(year)
    fixed(year).merge(relative_to_easter(year))
  end

  private

  def fixed(year)
    HOLIDAYS_FIXED.each_with_object({}) do |(month, day, name), hash|
      hash[Date.new(year, month, day)] = name
    end
  end

  def relative_to_easter(year)
    easter = easter_in(year)
    HOLIDAYS_RELATIVE_TO_EASTER.each_with_object({}) do |(offset, name), hash|
      hash[easter + offset] = name
    end
  end

  # Copyright by holidays gem
  # https://github.com/holidays/holidays/blob/master/lib/holidays/date_calculator/easter.rb
  def easter_in(year)
    y = year
    a = y % 19
    b = y / 100
    c = y % 100
    d = b / 4
    e = b % 4
    f = (b + 8) / 25
    g = (b - f + 1) / 3
    h = (19 * a + b - d - g + 15) % 30
    i = c / 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) / 451

    month = (h + l - 7 * m + 114) / 31
    day = ((h + l - 7 * m + 114) % 31) + 1

    Date.new(year, month, day)
  end
end
