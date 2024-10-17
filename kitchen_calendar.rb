#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate a PDF with a large calendar for the given or current year.
# Usage: `./kitchen_calendar.rb [year]`

require 'bundler/setup'
require 'date'
require 'prawn'
require 'prawn/measurement_extensions'

PAGE_SIZE = [900.mm, 162.mm].freeze
MARGIN = 12.mm

DEFAULT_FONT = 'Helvetica'
FONT_SIZE_TITLE = 40
FONT_SIZE_WDAY = 20
FONT_SIZE_DATE = 18
FONT_SIZE_CONTENT = 12
LEADING = 4

LINE_WIDTH = 1.5
TITLE_TOP = 133.mm
COLUMN_WIDTH = 28.mm
COLUMN_HEIGHT = 105.mm
PADDING_BOX = 3.mm
PADDING_TEXT = 4.mm
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

    date = Date.new(year, month, 1)
    while date.month == month
      offset = (date.day - 1) * COLUMN_WIDTH
      stroke_vertical_line(COLUMN_HEIGHT, 0, at: offset)

      # weekend background
      if [0, 6].include?(date.wday)
        fill_rectangle([offset + PADDING_BOX, COLUMN_HEIGHT],
                       COLUMN_WIDTH - PADDING_BOX,
                       FONT_SIZE_WDAY + LEADING)
        fill_color(WHITE) # for weekday label
      end
      # weekday label
      text_box(WEEKDAY_NAMES.fetch(date.wday),
               at: [offset + PADDING_TEXT, COLUMN_HEIGHT - LEADING],
               size: FONT_SIZE_WDAY)
      # date label
      fill_color(COLOR) # change back
      text_box("#{date.day}.#{date.month}.",
               at: [offset + PADDING_TEXT, COLUMN_HEIGHT - 2 * LEADING - FONT_SIZE_WDAY],
               size: FONT_SIZE_DATE)
      # Z: (für Znacht)
      text_box('Z:',
               at: [offset + PADDING_TEXT, Z_TOP],
               size: FONT_SIZE_CONTENT)

      date = date.next
    end
    stroke_vertical_line(COLUMN_HEIGHT, 0, at: date.prev_day.day * COLUMN_WIDTH)
  end
end

`open #{filename} &`
