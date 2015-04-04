# VexTab Player
# Copyright 2012 Mohit Cheppudira <mohit@muthanna.com>
#
# This class is responsible for rendering the elements
# parsed by Vex.Flow.VexTab.

Vex = require 'vexflow'
Pencil = require 'penciljs'
_ = require 'lodash'
class Vex.Flow.Player
  @DEBUG = false
  @INSTRUMENTS_LOADED = {}
  L = (args...) -> console?.log("(Vex.Flow.Player)", args...) if Vex.Flow.Player.DEBUG

  Fraction = Vex.Flow.Fraction
  RESOLUTION = Vex.Flow.RESOLUTION
  noteValues = Vex.Flow.Music.noteValues
  drawDot = Vex.drawDot

  INSTRUMENTS = {
    "acoustic_grand_piano": 0,
    "acoustic_guitar_nylon": 24,
    "acoustic_guitar_steel": 25,
    "electric_guitar_jazz": 26,
    "distortion_guitar": 30,
    "electric_bass_finger": 33,
    "electric_bass_pick": 34,
    "trumpet": 56,
    "brass_section": 61,
    "soprano_sax": 64,
    "alto_sax": 65,
    "tenor_sax": 66,
    "baritone_sax": 67,
    "flute": 73,
    "synth_drum": 118
  }

  constructor: (@artist, options) ->
    L "Initializing player: ", options
    @options =
      instrument: "acoustic_grand_piano"
      tempo: 120
      show_controls: false
      soundfont_url: "lib/soundfont/"
      overlay_class: "vextab-player"

    _.extend(@options, options) if options?
    L "Using soundfonts in: #{@options.soundfont_url}"
    @interval_id = null
    @pencil = null
    @reset()

  setArtist: (artist) ->
    @artist = artist
    @reset()

  setTempo: (tempo) ->
    L "New tempo: ", tempo
    @options.tempo = tempo
    @reset()

  setInstrument: (instrument) ->
    L "New instrument: ", instrument
    if instrument not in _.keys(INSTRUMENTS)
      throw new Vex.RERR("PlayerError", "Invalid instrument: " + instrument)
    @options.instrument = instrument
    @reset()

  reset: ->
    @artist.attachPlayer(this)
    @tick_notes = {}
    @all_ticks = []
    @tpm = @options.tempo * (RESOLUTION / 4)
    @refresh_rate = 25 #ms: 50 = 20hz
    @ticks_per_refresh = @tpm / (60 * (1000/@refresh_rate))
    @total_ticks = 0
    if @marker?
      @marker.remove()
      @marker = null
    @stop()

  getOverlay = (context, scale, overlay_class) ->
    canvas = context.canvas
    height = canvas.height
    width = canvas.width

    overlay = $('<canvas>')
    overlay.css("position", "absolute")

    overlay.css("left", $(canvas).position().left)
    overlay.css("top", $(canvas).position().top)
    overlay.addClass(overlay_class)

    $(canvas).after(overlay)
    ctx = Vex.Flow.Renderer.getCanvasContext(overlay.get(0), width, height)
    ctx.scale(scale, scale)

    pencil = new Pencil(overlay.get(0))

    return {
      pencil: pencil
      canvas: overlay.get(0)
    }

  removeControls: ->
    @play_button.remove() if @play_button?
    @stop_button.remove() if @stop_button?
    @pencil.draw() if @pencil?

  render: ->
    @reset()
    data = @artist.getPlayerData()
    @scale = data.scale

    if not @pencil
      overlay = getOverlay(data.context, data.scale, @options.overlay_class)
      @pencil = overlay.pencil

    @marker = new Pencil.Rectangle(0,0,8,75).by(@pencil).setContext({globalAlpha:0})

    if @options.show_controls and not @pencil?.rendered

      @play_button = new Pencil.RegularPolygon(10,12, 8, 3).by @pencil

      @play_button.setContext
        fillStyle : '#0dad51'
        strokeStyle : '#0dad51'
      @play_button.on 'click', (event) =>
        @play()

      @stop_button = new Pencil.Rectangle(35,5,14,14).by @pencil
      @stop_button.setContext
        fillStyle  : '#0dad51'
        strokeStyle : '#0dad51'
      @stop_button.on 'click', (event) =>
        @stop()
      @pencil.rendered = true

    @pencil.draw()
    staves = data.voices

    total_ticks = new Fraction(0, 1)
    for voice_group in staves
      max_voice_tick = new Fraction(0, 1)
      for voice, i in voice_group
        total_voice_ticks = new Fraction(0, 1)

        for note in voice.getTickables()
          unless note.shouldIgnoreTicks()
            abs_tick = total_ticks.clone()
            abs_tick.add(total_voice_ticks)
            abs_tick.simplify()
            key = abs_tick.toString()

            if _.has(@tick_notes, key)
              @tick_notes[key].notes.push(note)
            else
              @tick_notes[key] =
                tick: abs_tick
                value: abs_tick.value()
                notes: [note]

            total_voice_ticks.add(note.getTicks())

        if total_voice_ticks.value() > max_voice_tick.value()
          max_voice_tick.copy(total_voice_ticks)

      total_ticks.add(max_voice_tick)

    @all_ticks = _.sortBy(_.values(@tick_notes), (tick) -> tick.value)
    @total_ticks = _.last(@all_ticks)
    L @all_ticks

  updateMarker: (x, y) ->
    @marker.setContext
      fillStyle : '#0dad51'
      strokeStyle : '#0dad51'
      globalAlpha : 0.3
    @marker.setPosition( x, (y - 10))
    @pencil.draw()

  playNote: (notes) ->
    L "(#{@current_ticks}) playNote: ", notes

    for note in notes
      x = note.getAbsoluteX() + 2
      y = note.getStave().getYForLine(0)
      @updateMarker(x, y) if @pencil?
      continue if note.isRest()

      keys = note.getPlayNote()
      duration = note.getTicks().value() / (@tpm/60)
      for key in keys
        [note, octave] = key.split("/")
        note = note.trim().toLowerCase()
        note_value = noteValues[note]
        continue unless note_value?

        midi_note = (24 + (octave * 12)) + noteValues[note].int_val
        MIDI.noteOn(0, midi_note, 127, 0)
        MIDI.noteOff(0, midi_note, duration)

  refresh: ->
    if @done
      @stop()
      return

    @current_ticks += @ticks_per_refresh

    if @current_ticks >= @next_event_tick and @all_ticks.length > 0
      @playNote @all_ticks[@next_index].notes
      @next_index++
      if @next_index >= @all_ticks.length
        @done = true
        if @onEnd
          do @onEnd
      else
        @next_event_tick = @all_ticks[@next_index].tick.value()

  stop: ->
    L "Stop"
    window.clearInterval(@interval_id) if @interval_id?
    @interval_id = null
    @current_ticks = 0
    @next_event_tick = 0
    @next_index = 0
    @done = false

  start: ->
    @stop()
    L "Start"
    MIDI.programChange(0, INSTRUMENTS[@options.instrument])
    @render() # try to update, maybe notes were changed dynamically
    @interval_id = window.setInterval((() => @refresh()), @refresh_rate)

  play: ->
    L "Play: ", @refresh_rate, @ticks_per_refresh
    if Vex.Flow.Player.INSTRUMENTS_LOADED[@options.instrument] and not @loading
      @start()
    else
      L "Loading instruments..."
      # @loading_message.content = "Loading instruments..."
      # @loading_message.fillColor = "green"
      @loading = true
      @pencil.draw()

      MIDI.loadPlugin
        soundfontUrl: @options.soundfont_url
        instruments: [@options.instrument]
        callback: () =>
          Vex.Flow.Player.INSTRUMENTS_LOADED[@options.instrument] = true
          @loading = false
          # @loading_message.content = ""
          @start()
