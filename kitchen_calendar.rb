#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate a PDF with a large calendar for the given or current year.
# Usage: `./kitchen_calendar.rb [year]`

require 'bundler/setup'
require 'date'
require 'prawn'
require 'prawn/measurement_extensions'
require_relative 'holidays'

# Constants to configure layout and font

PAGE_SIZE = [900.mm, 162.mm].freeze
MARGIN = 12.mm

DEFAULT_FONT = 'Helvetica'
FONT_SIZE_TITLE = 40
FONT_SIZE_WDAY = 20
FONT_SIZE_DATE = 18
FONT_SIZE_CONTENT = 12
FONT_SIZE_HOLIDAY = 9
LEADING = 4

LINE_WIDTH = 1.5
TITLE_TOP = 133.mm
COLUMN_WIDTH = 28.mm
COLUMN_HEIGHT = 105.mm
PADDING_BOX = 3.mm
PADDING_TEXT = 4.mm

WEEKDAY_TOP = COLUMN_HEIGHT - LEADING
DATE_TOP = WEEKDAY_TOP - LEADING - FONT_SIZE_WDAY
HOLIDAY_TOP = DATE_TOP - LEADING - FONT_SIZE_DATE
Z_TOP = 20.mm

COLOR = '2a3773'
WHITE = 'FFFFFF'

MONTH_NAMES = %w[
  null
  Januar
  Februar
  März
  April
  Mai
  Juni
  Juli
  August
  September
  Oktober
  November
  Dezember
].freeze

WEEKDAY_NAMES = %w[
  So
  Mo
  Di
  Mi
  Do
  Fr
  Sa
].freeze


year = (ARGV[0] || Date.today.year).to_i
holidays = holiday_dates(year)
filename = "calendar-#{year}.pdf"
font = Dir.glob('./*.ttf').first || DEFAULT_FONT

Prawn::Document.generate(filename, page_size: PAGE_SIZE, margin: MARGIN) do
  font(font)
  stroke_color(COLOR)
  fill_color(COLOR)
  line_width(LINE_WIDTH)

  (1..12).each do |month|
    start_new_page if month > 1
    # month title
    text_box(MONTH_NAMES.fetch(month), at: [0, TITLE_TOP], size: FONT_SIZE_TITLE)

    stroke_vertical_line(COLUMN_HEIGHT, 0, at: 0)
    date = Date.new(year, month, 1)
    while date.month == month
      column_left = (date.day - 1) * COLUMN_WIDTH
      text_left = column_left + PADDING_TEXT
      stroke_vertical_line(COLUMN_HEIGHT, 0, at: column_left + COLUMN_WIDTH)

      # weekend background
      if [0, 6].include?(date.wday)
        fill_rectangle([column_left + PADDING_BOX, COLUMN_HEIGHT],
                       COLUMN_WIDTH - PADDING_BOX,
                       FONT_SIZE_WDAY + LEADING)
        fill_color(WHITE) # for weekday label
      end
      # weekday label
      text_box(WEEKDAY_NAMES.fetch(date.wday),
               at: [text_left, WEEKDAY_TOP],
               size: FONT_SIZE_WDAY)
      # date label
      fill_color(COLOR) # change back
      text_box("#{date.day}.#{date.month}.",
               at: [text_left, DATE_TOP],
               size: FONT_SIZE_DATE)
      # holiday name
      if holidays.key?(date)
        text_box(holidays[date],
                 at: [text_left, HOLIDAY_TOP],
                 size: FONT_SIZE_HOLIDAY,
                 width: COLUMN_WIDTH - PADDING_TEXT)
      end
      # Z: (für Znacht)
      text_box('Z:',
               at: [text_left, Z_TOP],
               size: FONT_SIZE_CONTENT)

      date = date.next
    end
  end
end

`open #{filename} &`
